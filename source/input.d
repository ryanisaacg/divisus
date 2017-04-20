import derelict.sdl2.sdl;

struct Keyboard {
	bool[SDL_Scancode] keys;
	
	void keyPress(SDL_Event e) {
		keys[e.key.keysym.scancode] = true;
	}
	
	void keyRelease(SDL_Event e) {
		keys.remove(e.key.keysym.scancode);
	}
	
	bool isPressed(string keyname)() {
		auto key = SDL_GetScancodeFromKey(SDL_GetKeyFromName(keyname));
		return (key in keys) !is null;
	}
}

struct Mouse {
    bool left, right, middle, x1, x2;
    int x, y, scrollX, scrollY;

    void update() {
        SDL_PumpEvents();
        auto buttonmask = SDL_GetMouseState(&x, &y);
        left = (buttonmask & SDL_BUTTON_LMASK) != 0;
        right = (buttonmask & SDL_BUTTON_RMASK) != 0;
        middle = (buttonmask & SDL_BUTTON_MMASK) != 0;
        x1 = (buttonmask & SDL_BUTTON_X1MASK) != 0;
        x2 = (buttonmask & SDL_BUTTON_X2MASK) != 0;
    }
}
