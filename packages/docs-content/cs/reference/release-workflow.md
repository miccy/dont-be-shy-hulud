# Release Workflow

Tento dokument popisuje proces vydávání nových verzí projektu **Don't Be Shy, Hulud!**.

## 1. Příprava
Ujistěte se, že máte:
- Čistý pracovní adresář (žádné necommitnuté změny).
- Jste na větvi `dev` (nebo jakékoliv `*-dev` větvi).
- Máte stažené nejnovější změny (`git pull`).

## 2. Spuštění procesu
Pro vydání nové verze použijte automatizační skript:

```bash
./scripts/release.sh
```

## 3. Průběh skriptu
Skript vás provede následujícími kroky:

1.  **Kontrola**: Ověří, zda jste na větvi `dev` (nebo `*-dev`) a nemáte rozpracované změny.
2.  **Volba verze**: Zobrazí aktuální verzi a zeptá se na novou.
3.  **Vytvoření větve**: Vytvoří novou větev `preview/vX.Y.Z`.
4.  **Úprava Changelogu**: Otevře `CHANGELOG.md` pro doplnění poznámek.
5.  **Synchronizace**: Aktualizuje verzi ve všech skriptech.
6.  **Push**: Commitne změny a odešle větev na GitHub.
7.  **Instrukce**: Vypíše odkaz pro vytvoření Pull Requestu.

## 4. Dokončení releasu (Automaticky)
1.  **Pull Request**: Otevřete PR z `preview/v...` do `main`.
2.  **Merge**: Po schválení mergněte PR do `main`.
    *   *Důležité:* Použijte **"Merge commit"** nebo **"Rebase and merge"**. Zachovejte commit message `chore: release v...`, aby GitHub Action poznala, že jde o release.
3.  **Automatický Release**:
    *   Jakmile se změny dostanou do `main`, spustí se GitHub Action `Automated Release`.
    *   Tato akce automaticky vytvoří **Git Tag** (např. `v1.4.0`) a **GitHub Release**.
4.  **Back-merge (Synchronizace dev)**:
    *   Jelikož se verze zvedla na `main`, musíte ji dostat zpět do `dev`.
    *   Vytvořte PR z `main` do `dev` nebo lokálně:
        ```bash
        git checkout dev
        git pull origin dev
        git merge main
        git push origin dev
        ```

## 5. Manuální postup (pokud skript selže)
Pokud potřebujete provést release ručně:

1.  Jděte na `dev`: `git checkout dev`.
2.  Vytvořte větev: `git checkout -b preview/v1.4.0`.
3.  Upravte `CHANGELOG.md` a spusťte `./scripts/sync-version.sh`.
4.  Commitněte a pushněte:
    ```bash
    git commit -am "chore: release v1.4.0"
    git push -u origin preview/v1.4.0
    ```
5.  Otevřete PR do `main`. Po mergi se release vytvoří sám.
