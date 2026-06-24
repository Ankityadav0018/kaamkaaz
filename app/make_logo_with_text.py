from PIL import Image, ImageDraw, ImageFont
import os

try:
    img = Image.open('assets/images/kaamkaaz_app_icon.png').convert("RGBA")
except Exception as e:
    print("Error opening image:", e)
    exit(1)

canvas_size = 1200
background = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))

# We want a small circle in the center, e.g., 280x280
circle_size = 280
circle_offset_x = (canvas_size - circle_size) // 2
circle_offset_y = (canvas_size - circle_size) // 2 - 120  # shift slightly up to make room for 2 lines of text

# Draw a white circle
mask = Image.new('L', (canvas_size, canvas_size), 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((circle_offset_x, circle_offset_y, circle_offset_x + circle_size, circle_offset_y + circle_size), fill=255)

# Create a white image
white_circle = Image.new('RGBA', (canvas_size, canvas_size), (255, 255, 255, 255))
background.paste(white_circle, (0, 0), mask)

# The logo should fit within the white circle with some padding
padding = int(circle_size * 0.16)
inner_size = circle_size - 2 * padding

# Resize the logo to fit inner_size
img.thumbnail((inner_size, inner_size), Image.Resampling.LANCZOS)

# Center the logo in the circle
offset_x = circle_offset_x + (circle_size - img.width) // 2
offset_y = circle_offset_y + (circle_size - img.height) // 2

# Paste the logo onto the background
background.paste(img, (offset_x, offset_y), img)

# Add text below
draw_bg = ImageDraw.Draw(background)

font_path = "/System/Library/Fonts/Supplemental/Arial.ttf"
if not os.path.exists(font_path):
    font_path = "/Library/Fonts/Arial.ttf"

try:
    bold_font_path = font_path.replace("Arial.ttf", "Arial Bold.ttf")
    if os.path.exists(bold_font_path):
        font_title = ImageFont.truetype(bold_font_path, 80)
    else:
        font_title = ImageFont.truetype(font_path, 80)
    font_sub = ImageFont.truetype(font_path, 40)
except:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()

title_text = "KAAMKAAZ"
sub_text = "Where Work Finds You"

title_bbox = draw_bg.textbbox((0, 0), title_text, font=font_title)
title_width = title_bbox[2] - title_bbox[0]

sub_bbox = draw_bg.textbbox((0, 0), sub_text, font=font_sub)
sub_width = sub_bbox[2] - sub_bbox[0]

# Draw Title
title_x = (canvas_size - title_width) // 2
title_y = circle_offset_y + circle_size + 30
draw_bg.text((title_x, title_y), title_text, fill=(255, 255, 255, 255), font=font_title)

# Draw Subtitle
sub_x = (canvas_size - sub_width) // 2
sub_y = title_y + 90
draw_bg.text((sub_x, sub_y), sub_text, fill=(255, 255, 255, 200), font=font_sub)

# Save
out_path = 'assets/images/kaamkaaz_splash_with_text.png'
background.save(out_path)
print("Created", out_path)
