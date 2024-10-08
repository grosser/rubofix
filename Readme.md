Auto fix all rubocop offenses with chatgpt / openai / local llm

Install
=======

```Bash
gem install rubofix
```

Usage
=====

- Get [openai key](https://platform.openai.com/settings/profile?tab=api-keys) and export as `RUBOFIX_API_KEY=`
  (for non-openai see "Options" below)
- Break something for rubocop (remove `# rubocop:disable` comment or remove `Enabled: false` from `.rubocop.yml`)

```bash
MAX=2 rubofix
# Fixing MAX=2 of 35 warnings with MODEL=gpt-4o-mini ...
# Fixing Rakefile:89:19: W: Lint/AssignmentInCondition: Use == if you meant to do a comparison ... with:
#  unless (template = args[:template])
# Fixing Rakefile:103:22: W: Lint/AssignmentInCondition: Use == if you meant to do a comparison ... with:
#    next unless (spec = e["spec"])
git diff
# Rakefile
#  -unless template = args[:template]
#  +unless (template = args[:template])
git commit -am 'fixing rubocop warnings'
```

### Options

- only fix given files `rubofix file1.rb file2.rb`
- `DEBUG=1` show prompt and answers
- `CONTEXT=10` feed 10 lines of context around the offense to the model
- `RUBOFIX_URL=` defaults to `https://api.openai.com`
- `RUBOFIX_API_KEY=`


Development
===========

- `rake` to run unit tests
- `rake integration` to run integration tests, they need an api key set
- `rake bump:<major|minor|patch>` to create a new version
- `rake release` to release a new version

TODO
====

- custom api endpoints
- local LLM support
- read rubocop.todo file and autofix everything in there
- retry on api failures
- parallel execution
- colored output
- try different temperatures to get better results
- try to send output back to llm with "check this makes sense" to fix bugs
- produce diffs and then apply them so we can fix multiple things in 1 file without changing line numbers


Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![coverage](https://img.shields.io/badge/coverage-100%25-success.svg)](https://github.com/grosser/single_cov)
