# PaintbruSh 🎨
![PaintbruSh Logo](https://i.imgur.com/6QdhCJy.png)

**PaintbruSh** is a terminal-based drawing application that allows you to create pixel art using keyboard navigation and controls. You can draw in different colors, toggle the pen on and off, and export your artwork to a PNG file.


## Installation
Clone the repository and navigate to the project directory. 

```bash
git clone https://github.com/JoroKudo/PaintbruSh.git
cd PaintbruSh
chmod +x paintbru.sh
```
Ensure that you have [ansilove](https://github.com/ansilove/ansilove) installed to enable image export functionality.

### Prerequisites
- **ansilove** (for exporting images): PaintbruSh uses `ansilove` to convert terminal drawings to PNG format.


## Usage
Run `paintbru.sh` to start drawing in the terminal.

```bash
./paintbru.sh
```

## Controls
These are the default controls, However they can be adjusted in the config file.

| Key     | Action                        |
| ------- | ----------------------------- |
| **a**   | Move left                     |
| **s**   | Move down                     |
| **d**   | Move right                    |
| **w**   | Move up                       |
| **q**   | Quit the application          |
| **SPACE** | Toggle pen (lift/lower)     |
| **[1-7]** | Select colors (1 through 7) |
| **0** | Select "eraser" (Black) |
| **x**   | Export drawing to PNG         |

> **Note:** Ensure `ansilove` is installed for exporting functionality.


Once you finish your artwork, press **x** to save it as a PNG file. The output file will be saved in the directory specified in the Config file.
