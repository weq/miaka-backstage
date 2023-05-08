# Backstage.io @ Miaka

The backstage.io deployment in Miaka.

## Creating the Backstage app

[Backstage: Create an App](https://backstage.io/docs/getting-started/create-an-app/)

- You need both `node` (16 or 18) & `yarn` to make the container. Use NVM to resolve the version compability with `node`.

1. Change the folder to app by entering `cd app`.
1. Then we execute `npx @backstage/create-app`.
1. Type in `backstage` as application name when prompted.

Hva jeg må løse?

Pipeline må bygge container.
Pipeline må pushe container.
Pipeline må trigge TF.
TF må deploye:
    Postgres
    AAD Apps for SSO
    AppService
    DNS records
    KeyVault