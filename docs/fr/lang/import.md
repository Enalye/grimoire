# Importer des fichiers

Un programme peut être réparti sur plusieurs fichiers.
Pour les importer, utilisez le mot-clé `import` suivi du chemin relatif du fichier.
```grimoire
import "foo/monScript.gr"

// Avec des accolades {} vous pouvez ajouter plusieurs fichiers à la fois.
import {
	"../lib/monAutreFichier.gr"
	"C:/MesScripts/script.gr"
}
```

Les chemins sont relatifs au fichier l’important.
Deux fichiers avec le même chemin absolu (càd le même fichier) ne seront inclus qu’une seule fois.