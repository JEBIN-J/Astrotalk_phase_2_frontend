# -*- coding: utf-8 -*-
with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'r', encoding='utf-8') as f:
    content = f.read()

bad_string = '''            } for p in planets_list
        ]
    } for p in planets_list
        ]
    }'''
good_string = '''            } for p in planets_list
        ]
    }'''

content = content.replace(bad_string, good_string)

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'w', encoding='utf-8') as f:
    f.write(content)
