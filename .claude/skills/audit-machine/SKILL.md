---
name: audit-machine
description: Régénère l'audit système d'un Mac dans docs/audit-<machine>.md de ce dépôt dotfiles — inventaire Homebrew/App Store/installs manuels/langages/services/disque, détection des casks fantômes, et dérive entre ce que install-deps.sh déclare et ce que la machine porte réellement. À utiliser dès que l'utilisateur parle d'auditer ou d'inventorier une machine, de rafraîchir ou mettre à jour un audit, de savoir ce qui est installé ou installé en double, de ce qui traîne hors de Homebrew, de casks fantômes, de dérive de configuration, ou de ce qui prend de la place sur le disque — même s'il ne prononce jamais le mot « audit », et même s'il demande juste « où on en est » sur une des machines.
---

# Régénérer un audit machine

Les audits de `docs/` sont des relevés datés qui périment vite. Ce skill
en produit un nouveau à partir de la machine courante, **sans perdre
l'historique des décisions** déjà consignées dedans.

Deux principes gouvernent tout le reste :

1. **Ce skill observe, il ne répare pas.** Le nettoyage appartient à
   `clean-mac.sh`, l'installation à `install-deps.sh`. Un audit qui
   modifie la machine qu'il mesure rend son propre relevé faux, et
   surprend l'utilisateur qui demandait un constat. Proposer les
   commandes correctives dans le document ; ne pas les exécuter.
2. **Aucun chiffre ne s'invente.** Tout ce qui est écrit vient de la
   sortie du collecteur ou d'une commande lancée exprès. Un audit dont
   on doit re-vérifier les chiffres ne sert à rien.

## Déroulé

### 1. Relever les faits

```bash
.claude/skills/audit-machine/scripts/collect-machine-facts.sh > /tmp/facts.txt
```

Lecture seule, ~10 s sans le disque, une à deux minutes avec (le `du` sur
`~/Library/Caches` est le poste lent). `--no-disk` saute cette partie
quand seul l'inventaire logiciel intéresse.

Le rapport est découpé par des marqueurs `===== SECTION =====`. Il fait
quelques centaines de lignes : le lire en entier, c'est la matière
première.

### 2. Identifier le fichier cible

Le `hostname` est en tête du rapport. Convention du dépôt, identique à
`detect_machine_role` dans `dotfiles-lib.sh` : un hostname contenant
`mac-mini` → `docs/audit-mac-mini.md`, tout le reste →
`docs/audit-macbook-pro.md`.

Lire **intégralement** le fichier existant avant d'écrire. Les findings
qu'il contient sont l'essentiel de sa valeur et l'étape 4 en dépend.

### 3. Régénérer l'inventaire

Réécrire les sections d'inventaire à partir des faits relevés, en suivant
`references/audit-template.md` pour l'ordre des sections et le ton.

Rédiger **en français**. Les audits existants sont en anglais : ils
basculent au fil de l'eau, section par section, à mesure qu'on les
retouche. Ne pas lancer de traduction générale d'un document au passage —
un diff de traduction noierait le diff de contenu, qui est ce que
l'utilisateur veut relire.

Deux choses méritent un traitement plus fin que la recopie :

- **Les installs manuels.** Le collecteur les liste, mais ne dit pas ce
  qu'il faut en penser. Pour chacun, vérifier s'il existe un cask
  (`brew search --cask <nom>`) : c'est ce qui transforme une liste en
  recommandation. Distinguer aussi ce qui n'est pas vraiment une install
  — produit de build, app vendue avec un périphérique.
- **La dérive vis-à-vis de `install-deps.sh`.** C'est ce qui donne sa
  valeur à l'audit, et personne d'autre ne le fait : comparer les paquets
  relevés avec ceux que le script déclare, dans les deux sens. Installé
  mais non déclaré → une reconstruction de la machine le perdrait.
  Déclaré mais absent → le script ment, ou l'install a échoué en silence.

### 4. Re-vérifier les findings existants

Ne jamais réécrire la section « Audit & recommandations » à partir de
zéro. Reprendre les items **avec leur numérotation d'origine** et, pour
chaque item encore ouvert, aller vérifier son état réel plutôt que de le
recopier : c'est précisément ce que le lecteur ne peut pas faire seul.

Presque tous les findings ont un signal vérifiable en une commande —
c'est ce qui les rend re-testables :

| Finding | Ce qui le vérifie |
|---|---|
| Docker.raw occupe N Go | la ligne `Docker.raw:` du rapport (apparent vs réel) |
| Cask fantôme | la section `GHOST CASKS` du rapport |
| Outil installé deux fois | présence dans deux inventaires à la fois |
| Stack déclarée ≠ stack réelle | section `LANGUAGE-LEVEL`, et `command -v` |
| Gestionnaire legacy revenu | les lignes `PRESENT:` du rapport |
| Pression disque | `df -h /` en tête de la section disque |

Puis mettre à jour le statut selon les conventions du gabarit : barré +
verdict en gras si c'est réglé, reste-à-faire explicite si c'est partiel,
chiffre réactualisé et daté si l'item a bougé sans être clos.

Les nouveaux constats s'ajoutent **à la fin**, avec un numéro neuf. Les
numéros existants sont cités dans les commits et dans les conversations :
renuméroter casse ces références.

Si le fichier porte un récapitulatif d'avancement (« Traités : 1
(partiel), 2 ✗, … »), le remettre à jour — c'est ce que l'utilisateur lit
en premier.

### 5. Dater et rendre la main

Le titre de la section inventaire porte la date du relevé
(`relevé AAAA-MM-JJ`). La mettre à jour : un audit sans date est
indistinguable d'un audit périmé.

Terminer en résumant ce qui a **changé depuis le relevé précédent** —
items clos, items ayant bougé, findings neufs. C'est l'information utile ;
le document, lui, est là pour être consulté plus tard.

Ne pas commiter sans que l'utilisateur le demande.

## Écueils

- **Un `PRESENT:` sur `~/.nvm`, `~/.pyenv` ou `~/.rvm` est un finding en
  soi**, pas une ligne d'inventaire. Ces trois-là ont été retirés des deux
  machines le 2026-08-28 et remplacés par asdf/uv/bun ; s'ils sont
  revenus, c'est qu'un installeur les a remis en douce, et c'est ça qu'il
  faut écrire.
- **Ne pas confondre absence d'outil et absence de paquets.** Le rapport
  écrit `(not installed: npm)` d'un côté et une liste vide de l'autre :
  « npm n'est pas là » et « npm n'a rien en global » appellent des
  conclusions opposées.
- **Le total `brew list --formula` n'est pas le nombre de paquets
  voulus.** L'écart avec `--installed-on-request` est constitué de
  dépendances transitives ; le rapport donne les deux, l'audit commente le
  second.
- **Le Mac mini n'a pas de section disque** dans son audit. Ne pas en
  ajouter une par symétrie.
