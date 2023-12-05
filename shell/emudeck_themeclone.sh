#!/usr/bin/env bash

themeclone () {
	project_name=$(echo "$1" | rev | cut -d"/" -f1 | rev | sed 's/.git$//g' | tr '[:upper:]' '[:lower:]')
	git clone "$1" "$HOME/.emulationstation/themes/$project_name"
}

themeclone https://github.com/anthonycaccese/alekfull-nx-es-de.git
themeclone https://github.com/anthonycaccese/art-book-next-es-de.git
themeclone https://github.com/anthonycaccese/atari-50-menu-es-de.git
themeclone https://github.com/Weestuarty/caralt-es-de.git
themeclone https://github.com/anthonycaccese/chicuelo-revisited-es-de.git
themeclone https://github.com/anthonycaccese/colorful-revisited-es-de.git
themeclone https://github.com/anthonycaccese/colorful-simplified-es-de.git
themeclone https://github.com/Weestuarty/elegance-es-de.git
themeclone https://github.com/anthonycaccese/epic-noir-revisited-es-de.git
themeclone https://github.com/Weestuarty/mini-es-de.git
themeclone https://github.com/anthonycaccese/immersive-revisited-es-de.git
themeclone https://github.com/anthonycaccese/mania-menu-es-de.git
themeclone https://github.com/anthonycaccese/mister-menu-es-de.git
themeclone https://gitlab.com/es-de/emulationstation-de.git
themeclone https://github.com/anthonycaccese/nso-menu-interpreted-es-de.git
themeclone https://github.com/anthonycaccese/retrofix-revisited-es-de.git
themeclone https://github.com/Weestuarty/showcase-es-de.git
themeclone https://github.com/Weestuarty/simcar-es-de.git
themeclone https://gitlab.com/es-de/emulationstation-de.git
themeclone https://github.com/Weestuarty/texgriddy-es-de.git
themeclone https://gitlab.com/es-de/themes/theme-engine-examples-es-de.git
