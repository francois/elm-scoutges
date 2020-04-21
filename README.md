# Scoutges

This project aims to help scout groups to manage their inventory and finances. The name "scoutges" comes from French:
"scout" and "gestion" (manage).

# Development

Setup your development environment:

    bin/setup

Follow the prompts to install every missing piece.

Useful commands:

    bin/dbconsole [ENV] # opens psql, to the named environment
    bin/mig SOME TEXT ... # opens your editor with any files in db/*/**/*.sql that match SOME and TEXT
                          # use: bin/mig tab ord #=> vim -o db/deploy/tables/orders.sql db/revert/tables/orders.sql ...


# Setting your expectations...

This project is a side-project of its main author. As such, it is in a constant state of flux. Expect frequent
breakages, huge refactorings, trials, errors and dead-ends.

At the time of writing, in April 2020, the project is barely started: the user can display the list of users and
parties. Otherwise, nothing else is implemented.

# LICENSE

Copyright 2020 François Beausoleil <francois@teksol.info>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

