Salut, je voulais te dire que ton code pour faire des téléchargement depuis anime-sama ne fonctionne plus correctement.
Déjà ils ont changé de nom de domaine et est devenu anime-sama.org (plus .fr), 
j'ai pu changer ça rapidement dans les paramètres de la requête 
mais je pense que la structure du site a aussi changé car je reçois toujours cette erreur:


```bash
~/Documents/Code/anime-sama/venv/lib/python3.13/site-packages/anime_sama_api/cli$ anime-sama
Anime name: One   
Traceback (most recent call last):
  File "/home/mathe/Documents/Code/anime-sama/venv/bin/anime-sama", line 8, in <module>
    sys.exit(main())
             ~~~~^^
  File "/home/mathe/Documents/Code/anime-sama/venv/lib/python3.13/site-packages/anime_sama_api/cli/__main__.py", line 68, in main
    asyncio.run(async_main())
    ~~~~~~~~~~~^^^^^^^^^^^^^^
  File "/usr/lib/python3.13/asyncio/runners.py", line 195, in run
    return runner.run(main)
           ~~~~~~~~~~^^^^^^
  File "/usr/lib/python3.13/asyncio/runners.py", line 118, in run
    return self._loop.run_until_complete(task)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^
  File "/usr/lib/python3.13/asyncio/base_events.py", line 725, in run_until_complete
    return future.result()
           ~~~~~~~~~~~~~^^
  File "/home/mathe/Documents/Code/anime-sama/venv/lib/python3.13/site-packages/anime_sama_api/cli/__main__.py", line 28, in async_main
    catalogues = await AnimeSama("https://anime-sama.org/").search(query)
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/mathe/Documents/Code/anime-sama/venv/lib/python3.13/site-packages/anime_sama_api/top_level.py", line 145, in search
    ).raise_for_status()
      ~~~~~~~~~~~~~~~~^^
  File "/home/mathe/Documents/Code/anime-sama/venv/lib/python3.13/site-packages/httpx/_models.py", line 829, in raise_for_status
    raise HTTPStatusError(message, request=request, response=self)
httpx.HTTPStatusError: Client error '403 Forbidden' for url 'https://anime-sama.org/catalogue/?search=One'
For more information check: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403
```

---

Il n'y a pas de moyen pour ouvrir un issue sur le repo archivé alors je pense que ce message sur ton repo le plus récent pour arriver à toi.
Alors je sais pas si tu voudras revoir ce code car comme tu as dit dans le readme tu sembles ne pas avoir trop de temps.

---

Merci pour ce que tu as fais, ton application m'a été très utile à moi et des amis. 
