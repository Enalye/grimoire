# Alias
Un alias de type permet de substituer un type à un autre.
```grimoire
func auCarré(i: int) (int) {
	return i * i;
};

alias MaFonction = func(int) (int);

event onLoad() {
    MaFonction maFonction = &<MaFonction> auCarré;
	10.maFonction.print;
}
```