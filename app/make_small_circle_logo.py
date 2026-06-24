from PIL import Image, ImageDraw

# Open the original logo
try:
    img = Image.open('assets/images/kaamkaaz_app_icon.png').convert("RGBA")
except Exception as e:
    print("Error opening image:", e)
    exit(1)

# Make a large transparent canvas so the actual logo appears small when centered
canvas_size = 1000
background = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))

# We want a small circle in the center, e.g., 300x300
circle_size = 350
circle_offset = (canvas_size - circle_size) // 2

# Draw a white circle
mask = Image.new('L', (canvas_size, canvas_size), 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((circle_offset, circle_offset, circle_offset + circle_size, circle_offset + circle_size), fill=255)

# Create a white image
white_circle = Image.new('RGBA', (canvas_size, canvas_size), (255, 255, 255, 255))
# Apply mask to make it a circle
background.paste(white_circle, (0, 0), mask)

# The logo should fit within the white circle with some padding
padding = int(circle_size * 0.16)
inner_size = circle_size - 2 * padding

# Resize the logo to fit inner_size
img.thumbnail((inner_size, inner_size), Image.Resampling.LANCZOS)

# Center the logo in the canvas
offset_x = (canvas_size - img.width) // 2
offset_y = (canvas_size - img.height) // 2

# Paste the logo onto the background
background.paste(img, (offset_x, offset_y), img)

# Save
background.save('assets/images/kaamkaaz_splash_small_circle.png')
print("Created kaamkaaz_splash_small_circle.png")
