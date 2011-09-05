local n = select(2, ...)

-- window settings
n.windowsettings = {
	pos = { "TOPLEFT", 4, -4 },
	width = 280,
	maxlines = 9,
	backgroundalpha = 1,
	scrollbar = true,

	titleheight = 16,
	titlealpha = 0.9,
	titlefont = [[Fonts\ARIALN.TTF]],
	titlefontsize = 13,
	titlefontcolor = {1, .82, 0},
	buttonhighlightcolor = {1, .82, 0},

	lineheight = 14,
	linegap = 1,
	linealpha = 1,
	linetexture = [[Interface\Tooltips\UI-Tooltip-Background]],
	linefont = [[Fonts\ARIALN.TTF]],
	linefontsize = 11,
	linefontcolor = {1, 1, 1},
}

-- core settings
n.coresettings = {
	refreshinterval = 1,
	minfightlength = 15,
	combatseconds = 3,
	shortnumbers = true,
}

-- available types and their order
n.types = {
	{
		name = "Damage",
		id = "dd",
		c = {.25, .66, .35},
	},
	{
		name = "Damage Targets",
		id = "dd",
		view = "Targets",
		onlyfights = true,
		c = {.25, .66, .35},
	},
	{
		name = "Damage Taken: Targets",
		id = "dt",
		view = "Targets",
		onlyfights = true,
		c = {.66, .25, .25},
	},
	{
		name = "Damage Taken: Abilities",
		id = "dt",
		view = "Spells",
		c = {.66, .25, .25},
	},
	{
		name = "Friendly Fire",
		id = "ff",
		c = {.63, .58, .24},
	},
	{
		name = "Healing + Absorbs",
		id = "hd",
		id2 = "ga",
		c = {.25, .5, .85},
	},
--	{
--		name = "Healing Taken: Abilities",
--		id = "ht",
--		view = "Spells",
--		c = {.25, .5, .85},
--	},
--	{
--		name = "Healing",
--		id = "hd",
--		c = {.25, .5, .85},
--	},
--	{
--		name = "Guessed Absorbs",
--		id = "ga",
--		c = {.25, .5, .85},
--	},
	{
		name = "Overhealing",
		id = "oh",
		c = {.25, .5, .85},
	},
	{
		name = "Dispels",
		id = "dp",
		c = {.58, .24, .63},
	},
	{
		name = "Interrupts",
		id = "ir",
		c = {.09, .61, .55},
	},
	{
		name = "Power Gains",
		id = "pg",
		c = {48/255, 113/255, 191/255},
	},
	{
		name = "Death Log",
		id = "deathlog",
		view = "Deathlog",
		onlyfights = true,
		c = {.66, .25, .25},
	},
}
