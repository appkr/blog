#!/usr/bin/env bash

# INSTALL GUIDE
#
# brew install ruby
# export PATH="$(brew --prefix ruby)/bin:$PATH"
#
# mkdir -p $HOME/gems
# export GEM_HOME=$HOME/gems
# export GEM_PATH=$HOME/gems
# export PATH=$GEM_HOME/bin:$PATH
#
# gem install bundler jekyll jekyll-paginate

git subtree push --prefix public origin gh-pages
