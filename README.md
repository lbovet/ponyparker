# PonyParker

![logo](https://user-images.githubusercontent.com/692124/167637146-088a57f8-2189-47fe-a01f-c029bd16b058.png)

Une toute petite application pour réserver la place de parking devant le bureau.

## Principe

- Réservation pour le jour-même jusqu'à 14h
- Réservation pour le lendemain dès 14h
- Priorité à ceux qui l'ont réservée le moins de fois
- Premier venu, premier servi en cas d'égalité
- Réservation annulable sans pénalité jusqu'à 20h
- Attribution définitive pour le lendemain à 20h
- Pénalité de priorité en cas d'annulation après 20h
- Pas de réservation le week-end et les jours fériés
- Bloquage possible à l'avance pour les visites par notre secrétariat

## Fonctionnement

- Authentification initiale depuis un appareil de l'entreprise
- Accès avec adresse codée transférable sur un autre appareil

## Développement

- Backend: [V](https://vlang.io/)
- Frontend: [jQuery](https://jquery.com/)
- Database: [PostgreSQL](https://www.postgresql.org/)

## Hébergement

- [Heroku](https://www.heroku.com/) Free Plan
