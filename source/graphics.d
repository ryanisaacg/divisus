import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;
import input;
import util;
import std.string;

enum BlendMode { None = SDL_BLENDMODE_NONE, Blend = SDL_BLENDMODE_BLEND, 
	Add = SDL_BLENDMODE_ADD, Mod = SDL_BLENDMODE_MOD};

int window_refs = 0; // the number of open windows

struct Window {
	SDL_Window *window; // the sdl window source
	Uint32 id;
	Keyboard keyboard, previousKeyboard;
	Mouse mouse, previousMouse;
	Renderer draw;
	int width, height;
	bool closed = false;
	
	this(string title, int width, int height, bool vsync = true) {
		//Load the libraries if this is the first window
		if(window_refs == 0) {
			DerelictSDL2.load();
			DerelictSDL2Image.load();
			checkError!SDL_GetError(SDL_Init(SDL_INIT_VIDEO) < 0, "SDL Initialization for window " ~ title);
			checkError!IMG_GetError(IMG_Init(IMG_INIT_PNG | IMG_INIT_JPG) != (IMG_INIT_PNG | IMG_INIT_JPG), "SDL_Image initialization");
		}
		window_refs ++;
		this.width = width;
		this.height = height;
		window = SDL_CreateWindow(title.toStringz(), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN);
		id = SDL_GetWindowID(window);
		draw = createRenderer(vsync);
	}
	
	void close() {
		window_refs --;
		draw.destroy();
		SDL_DestroyWindow(window);
		if(window_refs == 0) {
			SDL_Quit();
		}
	}

	void resetInput() {
		previousMouse = mouse;
		previousKeyboard.keys = keyboard.keys.dup;
	}
	
	void processEvent(Event event) {
		mouse.update();
		mouse.scrollX = mouse.scrollY = 0;
		switch(event.type) {
		case SDL_QUIT:
			closed = true;
			break;
		case SDL_KEYDOWN:
			if(event.key.windowID != id) return;
			keyboard.keyPress(event);
			break;
		case SDL_KEYUP:
			if(event.key.windowID != id) return;
			keyboard.keyRelease(event);
			break;
		case SDL_MOUSEWHEEL:
			if(event.wheel.windowID != id) return;
			mouse.scrollX = event.wheel.x;
			mouse.scrollY = event.wheel.y;
			break;
		default:
			break;
		}
	}
	
	Renderer createRenderer(bool vsync = true) {
		SDL_RendererFlags flags = SDL_RENDERER_ACCELERATED;
		flags |= (!vsync & SDL_RENDERER_PRESENTVSYNC);
		return Renderer(SDL_CreateRenderer(window, -1, flags));
	}	
}


struct Renderer {
	SDL_Renderer *renderer;
	private BlendMode blend = BlendMode.Blend;
	
	@nogc void destroy() {
		SDL_DestroyRenderer(renderer);
	}

	@nogc @property BlendMode mode() { return blend; }
	@nogc @property BlendMode mode(BlendMode b) {
		SDL_SetRenderDrawBlendMode(renderer, b);
		return blend = b;
	}

	@nogc void setTarget(Texture t) {
		SDL_SetRenderTarget(renderer, t.texture);
	}

	@nogc void resetTarget() {
		SDL_SetRenderTarget(renderer, null);
	}

	@nogc void draw(Texture t, int x = 0, int y = 0, int width = 0, int height = 0, double angle = 0, bool flipX = false, bool flipY = false, ubyte alpha = cast(ubyte)255) {
		SDL_SetTextureAlphaMod(t.texture, alpha);
		SDL_Rect source = t.sourceRect();
		SDL_Rect dest = SDL_Rect(x, y, width, height);
		SDL_Point point = SDL_Point(t.centerX, t.centerY);
		SDL_RendererFlip flip = SDL_FLIP_NONE | (SDL_FLIP_HORIZONTAL & flipX) | (SDL_FLIP_VERTICAL & flipY);
		int code = SDL_RenderCopyEx(renderer, t.texture, &source, &dest, angle, &point, flip);
		SDL_SetTextureAlphaMod(t.texture, 255);
	}

	Texture renderText(Font f, string text, Color c) {
		auto surface = TTF_RenderUTF8_Solid(f.font, text.toStringz(), c.rawColor());
		auto tex = Texture(this, surface);
		SDL_FreeSurface(surface);
		return tex;
	}

	@nogc void setColor(Color c) {
		SDL_SetRenderDrawColor(renderer, cast(ubyte)c.r, cast(ubyte)c.g, cast(ubyte)c.b, cast(ubyte)c.a);
	}

	@nogc void clear() {
		SDL_RenderClear(renderer);
	}

	@nogc void display() {
		SDL_RenderPresent(renderer);
	}

	@nogc void fillRect(int x, int y, int width, int height) {
		SDL_Rect rect = SDL_Rect(x, y, width, height);
		SDL_RenderFillRect(renderer, &rect);
	}
	
	Texture loadTexture(string path) {
		//Load surface from a file
		SDL_Surface *surface = IMG_Load(path.toStringz());
		checkError!SDL_GetError(surface == null, "Loading BMP file " ~ path);
		//Load texutre from surface
		SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
		checkError!SDL_GetError(texture == null, "Creating texture");
		//Clean up surface
		SDL_FreeSurface(surface);
		return Texture(texture);
	}
}

struct Texture {
	SDL_Texture *texture;
	int x = 0, y = 0;
	int width, height;
	int centerX = 0, centerY = 0;
	private BlendMode blend = BlendMode.Blend;

	@nogc this(SDL_Texture *tex) {
		texture = tex;
		SDL_QueryTexture(texture, null, null, &width, &height);
	}

	@nogc this(Renderer rend, int width, int height, bool renderTarget = false) {
		texture = SDL_CreateTexture(rend.renderer, SDL_PIXELFORMAT_RGBA8888, renderTarget ? SDL_TEXTUREACCESS_TARGET : SDL_TEXTUREACCESS_STATIC, width, height);
		this.width = width;
		this.height = height;
	}

	@nogc this(Renderer rend, SDL_Surface *surface) {
		this(SDL_CreateTextureFromSurface(rend.renderer, surface));
	}

	@nogc @property BlendMode mode() { return blend; }
	@nogc @property BlendMode mode(BlendMode b) {
		SDL_SetTextureBlendMode(texture, b);
		return blend = b;
	}
	
	@nogc void destroy() {
		SDL_DestroyTexture(texture);
	}
	
	@nogc SDL_Rect sourceRect() {
		return SDL_Rect(x, y, width, height);
	}
}

int font_refs = 0; //The number of existing font objects

enum FontStyle { Normal = TTF_STYLE_NORMAL, Bold = TTF_STYLE_BOLD, Italic = TTF_STYLE_ITALIC, Underline = TTF_STYLE_UNDERLINE, Strikethrough = TTF_STYLE_STRIKETHROUGH }

struct Font {
	TTF_Font *font;

	this(string name, int size) {
		if(font_refs == 0) {
			DerelictSDL2ttf.load();
			TTF_Init();
			checkError!TTF_GetError(TTF_Init() == -1, "Font library initialization failed");
		}
		font = TTF_OpenFont(name.toStringz(), size);
	}

	@nogc @property FontStyle style() { return cast(FontStyle)TTF_GetFontStyle(font); }
	@nogc @property FontStyle style(FontStyle style) { TTF_SetFontStyle(font, style); return style; }

	~this() {
		TTF_CloseFont(font);
		font_refs--;
		if(font_refs == 0) {
			TTF_Quit();
		}
	}
}

struct Color {
	int r, g, b, a; 

	@nogc SDL_Color rawColor() {
		return SDL_Color(cast(ubyte)r, cast(ubyte)g, cast(ubyte)b, cast(ubyte)a);
	}
}
