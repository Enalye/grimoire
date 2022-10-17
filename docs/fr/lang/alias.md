# Alias
Un alias de type permet de substituer un type à un autre.
```grimoire
function auCarré(int i) (int) {
	return i * i;
};

alias MaFonction = function(int) (int);

event onLoad() {
    MaFonction maFonction = @(MaFonction) auCarré;
	10:maFonction:print;
}
```