#!/bin/bash

jazzy \
  --author Lionheart \
  --author_url http://lionheartsw.com \
  --github_url https://github.com/lionheart/LionheartAlamofireClient \
  --github-file-prefix https://github.com/lionheart/LionheartAlamofireClient/tree/2.0.1 \
  --module LionheartAlamofireClient

git co gh-pages
cp -r docs/* .
rm -rf docs/
git add .
git commit -m "documentation update"
git co master
