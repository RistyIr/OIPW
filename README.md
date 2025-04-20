# 🛠️ Outil d’Intégration Personnalisée pour Windows PE

## 📌 Description

Cet outil open source permet de personnaliser facilement une image Windows (`install.wim` / `boot.wim`) en intégrant :

- des mises à jour (.msu)
- des pilotes
- des applications
- des fonds d’écran

Il a été conçu pour automatiser les étapes d'intégration lors de la création de clés USB bootables personnalisées.

---

## 📂 Structure des dossiers

Avant de lancer l’outil, il est important de respecter cette structure de répertoires :

- `wim/` → Contient le fichier `install.wim`
- `boot/` → Contient le fichier `boot.wim`
- `drivers/bootInsert/` → Pilotes à injecter dans le `boot.wim`
- `drivers/finalInsert/` → Pilotes à injecter dans le `install.wim`
- `applications/` → Applications à intégrer
- `wallpapers/` → Fonds d’écran personnalisés
- `updates/` → Mises à jour `.msu` pour **Windows 11 24H2**
- `updatele/` → Mises à jour `.msu` pour **Windows 11 23H2** ("le" pour *eleven*)
- `updateten/` → Mises à jour `.msu` pour **Windows 10 22H2**

---

## 🛠️ Instructions

1. **Modifier les chemins**

   Ouvrez les fichiers `.bat` et modifiez la variable `BASE` pour qu’elle pointe vers le chemin d’installation de l’outil sur votre machine.

2. **Ajouter les images WIM**
   - Placez votre fichier `install.wim` dans le dossier `wim/`
   - Placez votre fichier `boot.wim` dans le dossier `boot/`

3. **Intégrer les pilotes**
   - Pour `boot.wim` → Ajoutez les pilotes dans `drivers/bootInsert/`
   - Pour `install.wim` → Ajoutez les pilotes dans `drivers/finalInsert/`

4. **Ajouter des applications**

   Copiez toutes les applications que vous souhaitez intégrer dans `applications/`

5. **Personnaliser les fonds d’écran**

   Placez vos fonds d’écran personnalisés dans `wallpapers/`

6. **Ajouter les mises à jour Windows**

   Téléchargez les fichiers `.msu` depuis le [Catalogue Microsoft Update](https://www.catalog.update.microsoft.com/Home.aspx)  
   Copiez-les dans le dossier correspondant à la version ciblée (`updates/`, `updatele/`, `updateten/`)

---

## 🚀 Lancement

Exécutez le fichier `launch.bat` **en tant qu’administrateur** pour commencer le processus.

---

## 🐞 Bugs connus / Limites

- L’intégration des applications n’a pas encore été testée.
- Quelques erreurs ou comportements inattendus peuvent apparaître selon la version de Windows utilisée.
- Si une mise à jour `.msu` échoue, essayez de la retélécharger. Certains anciens fichiers peuvent devenir obsolètes ou corrompus.

---

## 🔓 Licence & Responsabilité

Ce projet est **open source**.

Vous êtes libre de l’utiliser, le modifier et le distribuer.  
Cependant, **je ne suis en aucun cas responsable de tout dommage ou mauvaise utilisation de cet outil**.  
Utilisez-le à vos propres risques.

---

## 🧠 Remarque

Le fonctionnement a été testé avec les images suivantes :

- Windows 10 22H2
- Windows 11 23H2
- Windows 11 24H2 (builds publics)

Certaines mises à jour `.msu` peuvent être incompatibles ou nécessiter un téléchargement régulier pour éviter les erreurs.

---

## 📬 Contribution

Pour toute suggestion ou contribution, vous pouvez ouvrir une *issue* ou un *pull request* sur le dépôt GitHub associé.
