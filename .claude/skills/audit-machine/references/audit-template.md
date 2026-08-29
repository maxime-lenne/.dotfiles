# Gabarit et conventions des audits

Squelette commun à `docs/audit-mac-mini.md` et `docs/audit-macbook-pro.md`.
Respecter l'ordre des sections : les deux fichiers se lisent en parallèle,
et une section déplacée d'un côté casse cette comparaison.

## Squelette

```markdown
# Audit système <Machine>

<Deux ou trois phrases de cadrage : quel rôle joue cette machine, et
comment lire les findings qui suivent. Le cadrage diffère par machine
et ne doit pas être régénéré mécaniquement — voir « Ton » plus bas.>

## Inventaire système (<Machine>, relevé <AAAA-MM-JJ>)

<Modèle, macOS, hostname. Puis la phrase qui dit d'où viennent les
chiffres : `brew leaves` / `brew list --installed-on-request`,
`system_profiler SPApplicationsDataType`, et la liste globale de chaque
gestionnaire de paquets.>

### Homebrew — formules installées explicitement (<N>)

### Homebrew — casks (<N>)

### Mac App Store (<N> apps)

### Installé manuellement (ni Homebrew, ni App Store)

### Installs globaux par langage

### Services en arrière-plan (`brew services list`)

### Occupation disque

## Audit & recommandations
```

La section « Occupation disque » n'existe que dans l'audit du poste de
travail. Ne pas l'inventer sur le Mac mini si elle n'y était pas : sur un
serveur headless c'est un non-sujet, et une section vide donne l'illusion
d'un relevé qui n'a pas eu lieu.

## Conventions des findings

Les findings sont une **liste numérotée qui porte un état**. Cet état est
la partie la plus coûteuse du document : il représente des décisions
prises et des vérifications faites, que le relevé brut ne permet pas de
reconstituer.

- **La numérotation est un identifiant stable.** Les items sont cités par
  numéro dans les messages de commit et dans les conversations
  (« l'item 6 »). Ne jamais renuméroter, ne jamais réordonner, ne jamais
  supprimer un item traité : un nouveau finding s'ajoute à la fin.
- **Traité = barré + verdict en gras**, l'énoncé d'origine restant
  lisible pour qu'on sache de quoi il s'agissait :

  ```markdown
  3. ~~Ollama occupe 41 Go en 5 modèles.~~ **Fait — les cinq supprimés**
     (`glm-4.7-flash` 19 Go, …). `~/.ollama` est retombé à 16 Ko.
  ```

- **Partiellement traité** : garder l'item ouvert, dire ce qui reste et
  comment le finir. Un « partiel » sans reste-à-faire explicite est un
  item qu'on rouvrira à l'aveugle dans six mois.
- **Un finding se termine par la commande qui le règle**, pas par un
  constat. `brew uninstall --cask --force github` vaut mieux que
  « nettoyer les casks obsolètes ».
- **Signaler ce qui est destructif** et ce qu'il faut vérifier avant
  (`docker system prune -a --volumes` supprime aussi les volumes).
- Les items sont **classés par impact décroissant** à leur création et
  gardent ensuite leur place.

## Ton

L'inventaire est factuel : des chiffres, des noms, des chemins.

Les findings sont un jugement, et le cadre de ce jugement dépend du rôle
de la machine :

- **Mac mini (serveur)** — l'objectif est le footprint minimal. Tout ce
  qui est GUI, IDE, ou hérité de l'époque poste de dev est un finding.
- **MacBook Pro (poste de travail)** — un gros footprint est l'état
  *attendu*. Les findings portent sur la **dérive et l'hygiène** :
  installé hors de tout gestionnaire, installé deux fois, stack déclarée
  vs stack réelle, pression disque. Pas sur le minimalisme.

Ne pas écraser le paragraphe de cadrage en tête de fichier : il porte
cette distinction, et il est écrit pour un lecteur humain qui arrive
froid sur le document.
