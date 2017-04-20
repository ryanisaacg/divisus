import derelict.sdl2.sdl;
import graphics;
import std.typecons;

alias Event = SDL_Event;

Nullable!Event pollEvent() {
    Event e;
    if(SDL_PollEvent(&e) == 1)
        return Nullable!Event(e);
    else
        return Nullable!Event();
}

void sleep(int millis) {
    SDL_Delay(millis);
}

template getError(alias errorFunc) {
	string getError() {
		string s;
		const(char)* cptr = errorFunc();
		while(*cptr != '\0') {
			s ~= *cptr;
			cptr++;
		}
		return s;
	}
}

template checkError(alias errorFunc) {
	void checkError(bool failed, string description) {
		if(failed) {
			string s = getError!errorFunc();
			throw new Exception("SDL Error: " ~ description ~ " failed (" ~ s ~ ")\n" );
		}
	}
}
