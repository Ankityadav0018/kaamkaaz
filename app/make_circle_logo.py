from PIL import Image, ImageDraw

# Open the original logo
try:
    img = Image.open('assets/images/kaamkaaz_app_icon.png').convert("RGBA")
except Exception as e:
    print("Error opening image:", e)
    exit(1)

# We want a white circle of say 500x500
size = 500
background = Image.new('RGBA', (size, size), (255, 255, 255, 0))

# Draw a white circle
mask = Image.new('L', (size, size), 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((0, 0, size, size), fill=255)

# Create a white image
white_circle = Image.new('RGBA', (size, size), (255, 255, 255, 255))
# Apply mask to make it a circle
background.paste(white_circle, (0, 0), mask)

# The logo should fit within a padded area. 
# In flutter, padding is 18 on a 110 circle. Ratio: 18/110 = 0.1636
padding = int(size * 0.1636)
inner_size = size - 2 * padding

# Resize the logo to fit inner_size
img.thumbnail((inner_size, inner_size), Image.Resampling.LANCZOS)

# Center the logo
offset_x = (size - img.width) // 2
offset_y = (size - img.height) // 2

# Paste the logo onto the background
background.paste(img, (offset_x, offset_y), img)

# Save
background.save('assets/images/kaamkaaz_splash_circle.png')
print("Created kaamkaaz_splash_circle.png")
