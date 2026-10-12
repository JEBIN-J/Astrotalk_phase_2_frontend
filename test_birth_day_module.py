import unittest
import sys
import os
import json

backend_path = os.path.abspath(os.path.join("..", "Astrotalk_phase_2_backend"))
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

from app import create_app
from app.services.birth_day_calculator import BirthDayNumberCalculator
from app.services.numerology_repository import NumerologyRepository

class TestBirthDayNumberModule(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = create_app()
        cls.client = cls.app.test_client()

    def test_all_31_calendar_days(self):
        """Verifies that all 31 days preserve the exact calendar day as the primary number."""
        for d in range(1, 32):
            dob = f"2000-01-{d:02d}"
            res = BirthDayNumberCalculator.calculate(dob)
            self.assertEqual(res["birth_day_number"], d, f"Failed for day {d}")

    def test_boundary_and_master_days(self):
        """Days 11 and 22 must remain 11 and 22 under primary method."""
        res_11 = BirthDayNumberCalculator.calculate("1995-07-11")
        self.assertEqual(res_11["birth_day_number"], 11)
        self.assertEqual(res_11["reduced_root"], 11)
        self.assertTrue(res_11["is_master_day"])

        res_22 = BirthDayNumberCalculator.calculate("1995-07-22")
        self.assertEqual(res_22["birth_day_number"], 22)
        self.assertEqual(res_22["reduced_root"], 22)
        self.assertTrue(res_22["is_master_day"])

    def test_day_29_preserves_29_with_master_root_11(self):
        """Day 29 must remain 29 even if its optional reduced root is 11."""
        res = BirthDayNumberCalculator.calculate("1990-05-29")
        self.assertEqual(res["birth_day_number"], 29)
        self.assertEqual(res["reduced_root"], 11)

    def test_day_31_preserves_31_with_root_4(self):
        """Day 31 must remain 31 with reduced root 4."""
        res = BirthDayNumberCalculator.calculate("1990-05-31")
        self.assertEqual(res["birth_day_number"], 31)
        self.assertEqual(res["reduced_root"], 4)

    def test_day_23_preserves_23_with_root_5(self):
        """Day 23 must remain 23 with reduced root 5."""
        res = BirthDayNumberCalculator.calculate("1990-05-23")
        self.assertEqual(res["birth_day_number"], 23)
        self.assertEqual(res["reduced_root"], 5)

    def test_leap_year(self):
        """Leap year date 2020-02-29 produces primary day 29."""
        res = BirthDayNumberCalculator.calculate("2020-02-29")
        self.assertEqual(res["birth_day_number"], 29)
        self.assertEqual(res["reduced_root"], 11)

    def test_invalid_dates_throw_error(self):
        with self.assertRaises(ValueError):
            BirthDayNumberCalculator.calculate("2023-02-29")  # Non-leap year
        with self.assertRaises(ValueError):
            BirthDayNumberCalculator.calculate("2023-04-31")  # April only 30 days
        with self.assertRaises(ValueError):
            BirthDayNumberCalculator.calculate("invalid")
        with self.assertRaises(ValueError):
            BirthDayNumberCalculator.calculate("")

    def test_content_completeness_all_31_days(self):
        """All 31 days must have published database records."""
        comp = NumerologyRepository.check_birth_day_completeness("pythagorean")
        self.assertTrue(comp["is_complete"])
        self.assertEqual(comp["total_available"], 31)
        self.assertEqual(len(comp["missing_days"]), 0)

    def test_all_sections_present(self):
        """Every day from 1 to 31 must contain all required sections."""
        for d in range(1, 32):
            interp = NumerologyRepository.get_birth_day_interpretation("pythagorean", d)
            self.assertIsNotNone(interp, f"Missing interp for day {d}")
            self.assertEqual(interp["birth_day_number"], d)
            self.assertGreaterEqual(len(interp["sections"]), 6)
            self.assertTrue(bool(interp["overview"]))
            self.assertIsInstance(interp["strengths"], list)
            self.assertIsInstance(interp["challenges"], list)
            self.assertTrue(bool(interp["personality_interpretation"]))
            self.assertTrue(bool(interp["relationship_interpretation"]))
            self.assertTrue(bool(interp["career_interpretation"]))
            self.assertTrue(bool(interp["personal_growth_guidance"]))
            self.assertIn("key_traits", interp["quick_summary"])

    def test_api_endpoint_success(self):
        res = self.client.get("/api/v1/numerology/birth-day?dob=1998-12-24&name=jebin%20j")
        self.assertEqual(res.status_code, 200)
        data = json.loads(res.data)
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["birth_day_number"], 24)
        self.assertEqual(data["reduced_root"], 6)
        self.assertEqual(data["number_title"], "The Loyal Family Pillar & Devoted Guardian")
        self.assertIn("interpretation", data)

    def test_api_endpoint_missing_dob(self):
        res = self.client.get("/api/v1/numerology/birth-day")
        self.assertEqual(res.status_code, 400)
        data = json.loads(res.data)
        self.assertEqual(data["error_code"], "MISSING_DATE_OF_BIRTH")

    def test_api_endpoint_invalid_dob(self):
        res = self.client.get("/api/v1/numerology/birth-day?dob=2021-02-29")
        self.assertEqual(res.status_code, 400)
        data = json.loads(res.data)
        self.assertEqual(data["error_code"], "INVALID_DATE_FORMAT")

if __name__ == "__main__":
    unittest.main()
