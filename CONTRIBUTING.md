# Contributing

Contributions are always welcome, no matter how large or small!

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project. Before contributing, please read the [code of conduct](./CODE_OF_CONDUCT.md).

## Development workflow

This project is a monorepo managed using [Yarn workspaces](https://yarnpkg.com/features/workspaces). It contains the following packages:

- The library package in the root directory.
- A bare React Native example app in `example/bare/`.
- An Expo example app in `example/expo/`.

To get started with the project, make sure you have the correct version of [Node.js](https://nodejs.org/) installed. See the [`.nvmrc`](./.nvmrc) file for the version used in this project.

Run `yarn` in the root directory to install the required dependencies for each package:

```sh
yarn
```

> Since the project relies on Yarn workspaces, you cannot use [`npm`](https://github.com/npm/cli) for development without manually migrating.

### Environment variables

The example apps require a Google Maps API key. Copy the example env files and add your key:

```sh
cp example/bare/.env.example example/bare/.env
cp example/expo/.env.example example/expo/.env
```

Then edit both `.env` files with your API key:

```
GOOGLE_MAPS_API_KEY=your_api_key_here
```

The [example app](/example/bare/) demonstrates usage of the library. You need to run it to test any changes you make.

It is configured to use the local version of the library, so any changes you make to the library's source code will be reflected in the example app. Changes to the library's JavaScript code will be reflected in the example app without a rebuild, but native code changes will require a rebuild of the example app.

If you want to use Android Studio or Xcode to edit the native code, you can open the `example/bare/android` or `example/bare/ios` directories respectively in those editors. To edit the Objective-C or Swift files, open `example/bare/ios/LuggMapsExample.xcworkspace` in Xcode and find the source files at `Pods > Development Pods > lugg-maps`.

To edit the Java or Kotlin files, open `example/bare/android` in Android studio and find the source files at `lugg-maps` under `Android`.

You can use various commands from the root directory to work with the project.

To start the packager:

```sh
yarn bare start
```

To run the example app on Android:

```sh
yarn bare android
```

To run the example app on iOS:

```sh
yarn bare ios
```

To confirm that the app is running with the new architecture, you can check the Metro logs for a message like this:

```sh
Running "LuggMapsExample" with {"fabric":true,"initialProps":{"concurrentRoot":true},"rootTag":1}
```

Note the `"fabric":true` and `"concurrentRoot":true` properties.

Make sure your code passes TypeScript:

```sh
yarn typecheck
```

To check for linting errors, run the following:

```sh
yarn lint
```

To fix formatting errors, run the following:

```sh
yarn lint --fix
```

Remember to add tests for your change if possible. Run the unit tests by:

```sh
yarn test
```


### Commit message convention

We follow the [conventional commits specification](https://www.conventionalcommits.org/en) for our commit messages:

- `fix`: bug fixes, e.g. fix crash due to deprecated method.
- `feat`: new features, e.g. add new method to the module.
- `refactor`: code refactor, e.g. migrate from class components to hooks.
- `docs`: changes into documentation, e.g. add usage example for the module.
- `test`: adding or updating tests, e.g. add integration tests using detox.
- `chore`: tooling changes, e.g. change CI config.

Our pre-commit hooks verify that your commit message matches this format when committing.


### Publishing to npm

We use [release-it](https://github.com/release-it/release-it) to make it easier to publish new versions. It handles common tasks like bumping version based on semver, creating tags and releases etc.

To publish new versions, run the following:

```sh
yarn release
```


### Scripts

The `package.json` file contains various scripts for common tasks:

- `yarn`: setup project by installing dependencies.
- `yarn typecheck`: type-check files with TypeScript.
- `yarn lint`: lint files with [ESLint](https://eslint.org/).
- `yarn test`: run unit tests with [Jest](https://jestjs.io/).
- `yarn bare start`: start the Metro server for the bare example app.
- `yarn bare android`: run the bare example app on Android.
- `yarn bare ios`: run the bare example app on iOS.
- `yarn expo start`: start the Metro server for the Expo example app.
- `yarn expo android`: run the Expo example app on Android.
- `yarn expo ios`: run the Expo example app on iOS.
- `yarn docs dev`: start the documentation site locally.

### Documentation

The documentation site lives in `docs/` and is built with [Next.js](https://nextjs.org/) and [Fumadocs](https://fumadocs.dev/). Pages are MDX files in `docs/content/docs/`. When you change a component or API, update the matching page there. The site deploys to [maps.lodev09.com](https://maps.lodev09.com).

### Sending a pull request

> **Working on your first pull request?** You can learn how from this _free_ series: [How to Contribute to an Open Source Project on GitHub](https://app.egghead.io/playlists/how-to-contribute-to-an-open-source-project-on-github).

When you're sending a pull request:

- Prefer small pull requests focused on one change.
- Verify that linters and tests are passing.
- Review the documentation to make sure it looks good.
- Follow the pull request template when opening a pull request.
- For pull requests that change the API or implementation, discuss with maintainers first by opening an issue.
