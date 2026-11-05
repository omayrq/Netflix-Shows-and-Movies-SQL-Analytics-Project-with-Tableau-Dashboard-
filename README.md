# Netflix Shows & Movies: SQL Server + Tableau Public Dashboard

A beginner-friendly, end-to-end data analytics project. You will download a Netflix dataset from Kaggle, load it into **SQL Server Management Studio (SSMS)**, analyse it with SQL, build a **Tableau Public** dashboard, and finally publish everything to **GitHub** using the command line.

**Tools used:** Kaggle (data), SQL Server + SSMS (analysis), Tableau Public (dashboard), Git + GitHub (sharing)

![Netflix Dashboard](images/netflix_dashboard.png)

> **Live dashboard:** `PASTE_YOUR_TABLEAU_PUBLIC_LINK_HERE`
> **Dataset:** [Netflix TV Shows and Movies on Kaggle](https://www.kaggle.com/datasets/victorsoeiro/netflix-tv-shows-and-movies)

---

## Table of Contents
1. [Business problem](#1-business-problem)
2. [Project structure](#2-project-structure)
3. [Step 1: Download the dataset from Kaggle](#step-1-download-the-dataset-from-kaggle)
4. [Step 2: Install SQL Server and SSMS](#step-2-install-sql-server-and-ssms)
5. [Step 3: Create a database and load the CSV files](#step-3-create-a-database-and-load-the-csv-files)
6. [Step 4: Analyse the data with SQL](#step-4-analyse-the-data-with-sql)
7. [Step 5: Export query results](#step-5-export-query-results)
8. [Step 6: Build the dashboard in Tableau Public](#step-6-build-the-dashboard-in-tableau-public)
9. [Step 7: Upload the project to GitHub with CMD](#step-7-upload-the-project-to-github-with-cmd)
10. [Key findings](#key-findings)
11. [Troubleshooting](#troubleshooting)

---

## 1. Business problem
Netflix has roughly 82,000 rows of data about its titles and the people who worked on them. The data is too large to read by hand, so the goal is to use SQL to pull out useful facts (best and worst rated titles, content by decade, age ratings, popular genres, and more) and present them in an interactive dashboard that anyone can understand at a glance.

## 2. Project structure
After finishing, your folder should look like this:

```
Netflix-SQLServer-Tableau-Dashboard/
├── README.md                     <- this file
├── Netflix_SQL_Analysis_SSMS.sql <- all queries for SQL Server (T-SQL)
├── Netflix_SQL_Analysis.sql      <- original MySQL version (kept for reference)
├── images/
│   └── netflix_dashboard.png     <- screenshot of the finished dashboard
└── .gitignore                    <- tells Git to skip the big CSV files
```

The two CSV files (`titles.csv`, `credits.csv`) are only needed on your computer, so they are not uploaded.

---

## Step 1: Download the dataset from Kaggle
1. Go to [kaggle.com](https://www.kaggle.com) and click **Register** (free). You can sign up with Google.
2. Open the [dataset page](https://www.kaggle.com/datasets/victorsoeiro/netflix-tv-shows-and-movies).
3. Click **Download** (top right). You get a `.zip` file.
4. Right-click the zip, choose **Extract All**, and move the two files into a working folder such as `C:\NetflixProject\data\`:
   - `titles.csv` : one row per movie or show (title, type, release year, genres, IMDB and TMDB scores, runtime, seasons, age certification, countries)
   - `credits.csv` : one row per actor or director per title (name, character, role)

Open `titles.csv` in Excel once to look at the columns. Knowing what is inside makes the SQL much easier.

---

## Step 2: Install SQL Server and SSMS
You need two separate things: the **database engine** (SQL Server) and the **tool to talk to it** (SSMS).

1. Download **SQL Server Developer** or **Express** (both free) from Microsoft's SQL Server downloads page. Choose the **Basic** install.
2. Download and install **SQL Server Management Studio (SSMS)** from Microsoft's SSMS page.
3. Open SSMS. In the *Connect to Server* window:
   - Server type: `Database Engine`
   - Server name: `localhost` (or `.\SQLEXPRESS` for Express)
   - Authentication: `Windows Authentication`
   - Tick **Trust server certificate** if it appears, then click **Connect**.

---

## Step 3: Create a database and load the CSV files

### 3.1 Create the database
Click **New Query** and run:

```sql
CREATE DATABASE NetflixDB;
GO
USE NetflixDB;
GO
```

### 3.2 Import `titles.csv`
1. In **Object Explorer**, expand *Databases*, right-click **NetflixDB**, then choose **Tasks → Import Flat File…**
2. Click **Next**, then **Browse** and select `titles.csv`. Name the new table `titles`. Keep the schema as `dbo`. Click **Next**.
3. On the *Modify Columns* page check the data types. Important fixes:
   - Set `description` to `nvarchar(MAX)` (long text will fail otherwise).
   - `imdb_score`, `tmdb_score`, `tmdb_popularity` → `float`; tick **Allow Nulls**.
   - `release_year`, `runtime`, `seasons`, `imdb_votes` → `int` or `float`; tick **Allow Nulls**.
   - Everything else can stay as `nvarchar`. Do **not** tick *Primary Key* on `id` (the file may contain repeats).
4. Click **Next → Finish**. You should see *Success*.

### 3.3 Import `credits.csv`
Repeat the same steps and name the table `credits`. Set `name` and `character` to `nvarchar(200)` or larger.

### 3.4 Check the import
```sql
SELECT COUNT(*) FROM dbo.titles;    -- roughly 5,800 rows
SELECT COUNT(*) FROM dbo.credits;   -- roughly 77,000 rows
SELECT TOP 5 * FROM dbo.titles;
```
If the counts are far lower than expected, see [Troubleshooting](#troubleshooting).

---

## Step 4: Analyse the data with SQL
Open `Netflix_SQL_Analysis_SSMS.sql` in SSMS. **Highlight one query at a time** and press **F5**.

> Note: the original project used MySQL (`LIMIT 10`). SQL Server uses `SELECT TOP 10` instead. The `_SSMS.sql` file already has every query converted.

### Question 1: Top and bottom 10 by IMDB score
```sql
SELECT TOP 10 title, type, imdb_score
FROM dbo.titles
WHERE type = 'MOVIE' AND imdb_score >= 8.0
ORDER BY imdb_score DESC;
```
Change `DESC` to `ASC` (and remove the `>= 8.0` filter) for the bottom 10. Repeat with `type = 'SHOW'` for shows.

*How it works:* `WHERE` keeps only the rows you want, `ORDER BY` sorts them, and `TOP 10` keeps the first ten.

### Question 2: How many titles per decade?
```sql
SELECT CONCAT(FLOOR(release_year / 10) * 10, 's') AS decade,
       COUNT(*) AS movies_shows_count
FROM dbo.titles
WHERE release_year >= 1940
GROUP BY CONCAT(FLOOR(release_year / 10) * 10, 's')
ORDER BY decade;
```
*How it works:* dividing the year by 10, rounding down, and multiplying by 10 turns 2017 into 2010. `GROUP BY` then counts titles per decade.

### Question 3: Average scores and age certifications
```sql
SELECT age_certification,
       ROUND(AVG(imdb_score), 2) AS avg_imdb_score,
       ROUND(AVG(tmdb_score), 2) AS avg_tmdb_score
FROM dbo.titles
GROUP BY age_certification
ORDER BY avg_imdb_score DESC;

SELECT TOP 5 age_certification, COUNT(*) AS certification_count
FROM dbo.titles
WHERE type = 'MOVIE' AND age_certification IS NOT NULL AND age_certification <> 'N/A'
GROUP BY age_certification
ORDER BY certification_count DESC;
```

### Question 4: Most common genres
```sql
SELECT TOP 10 genres, COUNT(*) AS title_count
FROM dbo.titles
WHERE type = 'MOVIE'
GROUP BY genres
ORDER BY title_count DESC;
```
Use `type = 'SHOW'` for shows, or drop the `WHERE` line for both together.

### More queries
The `.sql` file also covers: average scores for movies vs shows, titles per production country, shows with the most seasons, average runtime, top actors and directors, and actors who played the same character more than once.

---

## Step 5: Export query results
**Tableau Public cannot connect directly to SQL Server** (that feature needs paid Tableau Desktop). The workaround is to export each result as a CSV and connect Tableau to the files.

1. Run a query in SSMS.
2. Right-click inside the **Results** grid → **Save Results As…**
3. Save as CSV in a folder like `C:\NetflixProject\tableau_data\`, using clear names:

| Query | File name |
|---|---|
| Top 10 movies | `top10_movies.csv` |
| Top 10 shows | `top10_shows.csv` |
| Bottom 10 movies | `bottom10_movies.csv` |
| Bottom 10 shows | `bottom10_shows.csv` |
| Titles per decade | `titles_by_decade.csv` |
| Titles per country | `titles_by_country.csv` |
| Top 5 age certifications | `age_certifications.csv` |
| Avg IMDB and TMDB by type | `avg_scores_by_type.csv` |
| Shows with most seasons | `most_seasons.csv` |

Tip: SSMS exports without column headers by default. In **Tools → Options → Query Results → SQL Server → Results to Grid**, tick **Include column headers when copying or saving the results**, then rerun the query before saving.

---

## Step 6: Build the dashboard in Tableau Public
### 6.1 Install and connect
1. Download **Tableau Public** (free) from public.tableau.com and create a free account.
2. Open it. Under **Connect**, choose **Text file** and pick your first CSV (for example `top10_movies.csv`).
3. For every extra CSV, click the sheet tab at the bottom, then **New Data Source → Text file** and add the next file.

### 6.2 Build each chart (one worksheet per chart)
Click a new worksheet tab at the bottom for each one.

| Worksheet | How to build it |
|---|---|
| **Top 10 IMDB Movies / Shows** | Drag `title` to *Rows*, drag `imdb_score` to *Text* and to *Color*. Choose the red colour palette. Sort descending. |
| **Bottom 10 IMDB Movies / Shows** | Same as above using the bottom-10 files. |
| **Movies & Shows by Decade** | Drag `decade` to *Rows*, `movies_shows_count` to *Columns*. Chart type: **Bar**. Add the count to *Label*. |
| **Production Countries Map** | Drag `country` to the view. Tableau makes a map automatically. Drag `title_count` to *Color* and *Label*. Use **Map → Map Layers** to pick a dark background. |
| **Top 5 Age Certifications** | Drag `age_certification` to *Color* and *Label*, `certification_count` to *Angle*. Mark type: **Pie**. |
| **Avg IMDB and TMDB Scores** | Use `avg_scores_by_type.csv`. Drag `type` to *Columns* and the two score columns to *Rows* (or use **Measure Names / Measure Values**). Chart type: **Bar**. |
| **Top 10 Shows with Most Seasons** | Drag `title` to *Columns* and `total_seasons` to *Rows*. Mark type: **Line**. Add the value to *Label*. |

For each sheet: right-click the title to edit it, make it red, and use **Format → Shading** to set a dark background.

### 6.3 Assemble the dashboard
1. Click the **New Dashboard** icon (bottom tab bar).
2. Set **Size** to *Automatic* or *Fixed: 1600 x 900*.
3. Drag each worksheet onto the canvas. Use the layout from the screenshot:
   - Top row: the logo/title block, then four ranking tables.
   - Middle left: the map.
   - Middle: decade bars and the seasons line chart.
   - Right: age-certification pie and average-score bars.
4. Add a **Text** object for the title: `NETFLIX SHOWS & MOVIES DASHBOARD` in bold red (`#E50914`).
5. Set the dashboard background to black or dark grey via **Dashboard → Format**.

### 6.4 Publish
1. **File → Save to Tableau Public As…**
2. Sign in and give the workbook a name such as `Netflix Shows Movies Dashboard`.
3. Your browser opens the live dashboard. Copy the link and paste it at the top of this README.
4. Take a screenshot (or use **Dashboard → Export Image**) and save it as `images/netflix_dashboard.png` in your project folder.

---

## Step 7: Upload the project to GitHub with CMD

### 7.1 One-time setup
1. Install Git from git-scm.com (keep all defaults).
2. Create a free account at github.com.
3. Open **Command Prompt** (press the Windows key, type `cmd`, press Enter) and verify Git works:
```cmd
git --version
```
4. Tell Git who you are (use the same email as your GitHub account):
```cmd
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### 7.2 Prepare the folder with a relevant name
Rename your project folder so it describes the work, for example `Netflix-SQLServer-Tableau-Dashboard`:
```cmd
cd C:\NetflixProject
ren "Old Folder Name" Netflix-SQLServer-Tableau-Dashboard
cd Netflix-SQLServer-Tableau-Dashboard
```
Make sure the folder contains `README.md`, `Netflix_SQL_Analysis_SSMS.sql`, and an `images` folder with `netflix_dashboard.png`.

Create a `.gitignore` so the large CSV files are not uploaded:
```cmd
echo *.csv> .gitignore
echo *.twbx>> .gitignore
```

### 7.3 Create the empty repository on GitHub
1. Log in to GitHub and click the **+** (top right) → **New repository**.
2. Repository name: `Netflix-SQLServer-Tableau-Dashboard`.
3. Add a short description, choose **Public**.
4. **Do not** tick *Add a README* or *.gitignore* (you already have them).
5. Click **Create repository**.

### 7.4 Push your files
Run these in CMD from inside the project folder. Replace `YOUR_USERNAME` with your GitHub username.

```cmd
git init
git add .
git commit -m "Add Netflix SQL Server analysis and Tableau dashboard"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/Netflix-SQLServer-Tableau-Dashboard.git
git push -u origin main
```

When asked to sign in, a browser window opens: log in and authorize. If it asks for a password instead, GitHub no longer accepts account passwords on the command line, so create a **Personal Access Token** (GitHub → *Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate*, tick `repo`) and paste that as the password.

Refresh your GitHub page; the files should appear.

### 7.5 Updating later
Whenever you change something:
```cmd
git add .
git commit -m "Describe what you changed"
git push
```

### Handy commands
| Command | What it does |
|---|---|
| `git status` | Shows changed and untracked files |
| `git log --oneline` | Shows commit history |
| `git remote -v` | Shows which GitHub repo you are linked to |
| `git pull` | Downloads the latest changes from GitHub |

---

## Key findings
Numbers come from the dashboard built on this dataset.

- **Quality:** Breaking Bad and Khawatir (both 9.5) lead the shows; Major and Chhota Bheem & Krishna (9.0) lead the movies. At the bottom, Nothing to Lose (2.3) and Time to Dance (2.2) are the lowest-rated movies. Scores vary because of plot, acting, production quality, and personal taste.
- **Growth:** The library jumps sharply from the 2000s (369 titles) to the 2010s (3,304). The 2020s already hold 1,972 titles despite being unfinished, so Netflix leans heavily on recent content.
- **Where content is made:** The United States leads with 1,959 titles, followed by India (599), then the United Kingdom and other countries.
- **Age ratings:** R is the most common movie certification (556), then PG-13 (451), PG (233), G (124), and NC-17 (16). TV-14 content has the highest average IMDB score (about 6.7).
- **Scores by type:** Shows score higher than movies on both sites (IMDB 6.42 vs 5.72, TMDB 7.07 vs 6.13).
- **Genres:** Comedy is the most common genre overall, followed by documentation and drama. Mixed genres such as comedy + drama and drama + romance are also frequent.
- **Long runners:** Survivor tops the seasons chart at 42, followed by Wheel of Fortune (39) and The Challenge (37).

---

## Troubleshooting
| Problem | Fix |
|---|---|
| Import Flat File fails with a "truncation" error | Set long text columns (like `description`) to `nvarchar(MAX)` on the *Modify Columns* page. |
| Row count is much lower than expected | Text fields with commas/quotes break the wizard. Re-run it and set the text qualifier, or use **Tasks → Import Data** with the *Flat File Source*. |
| `Invalid object name 'dbo.titles'` | Run `USE NetflixDB;` first, or choose NetflixDB in the toolbar dropdown. |
| `Incorrect syntax near 'LIMIT'` | That is MySQL. Use `SELECT TOP n` in SQL Server. |
| Tableau Public has no SQL Server option | Expected. Export to CSV (Step 5) and connect via **Text file**. |
| `git push` says `remote origin already exists` | Run `git remote set-url origin https://github.com/YOUR_USERNAME/REPO.git`. |
| `git push` is rejected (`fetch first`) | Run `git pull origin main --allow-unrelated-histories`, then push again. |
| `'git' is not recognized` | Close and reopen CMD after installing Git, or reinstall it. |

---

*Dataset credit: Victor Soeiro on Kaggle. Project built for learning purposes.*
