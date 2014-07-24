# Mura Elasticsearch

Based on http://github.com/oscarduignan/mura-plugin-elasticsearch which was developed for MuraCon EU 2014 ([view the presentation slides](https://docs.google.com/presentation/d/12OF8i1deFDXKVXjP9bC0S6fEzdgjtoXbvQM8fa4GVek/pub?start=false&loop=false&delayms=3000)
).

This plugin indexes the content of your mura sites with Elasticsearch for you, keeping your Elasticsearch index synced with your mura content automatically. Elasticsearch is a database optimized for search and with it you gain a better basic search and a more solid foundation to build advanced search functionality on top of in exchange for a slightly higher upfront setup cost (that this plugin is created to lower as much as possible). This plugin is intended as a foundation for you to develop on, not a plug-and-play replacement for the existing mura search.

Read more about elasticsearch at http://www.elasticsearch.org/overview/elasticsearch/.

## How to install

[Download the latest release](https://github.com/binaryvision/mura-elasticsearch/releases) and upload the zip as a plugin to your Mura installation.

## How to contribute

Once you've installed the plugin you can replace the plugin directory with a checkout of the source code from github.

The git workflow we're using is Github Flow - read more about it at https://guides.github.com/introduction/flow/index.html.

### Tests

We're using testbox v2.0.0 or later as our testing framework, if you want to run tests then you'll need to make sure that /testbox exists. I would recommend just dropping it in your local webroot, download instructions at http://wiki.coldbox.org/wiki/TestBox.cfm#Download.

See existing tests for examples of how to structure your own.

## Roadmap

Find out what we're working on at https://trello.com/b/duJkz7Xs/mura-elasticsearch

(Ask [@oscarduignan](https://github.com/oscarduignan) if you want access)

## Changelog

Find our release notes at https://github.com/binaryvision/mura-elasticsearch/releases

## Where to get help

* Oscar Duignan, [@oscarduignan](https://github.com/oscarduignan) on github and [@socialpoetry](https://twitter.com/socialpoetry) on twitter

    > Project maintainer, good first point of call if you have a question.
