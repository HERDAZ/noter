# NOTER
Small bash program that (badly) manages journals, with a little integration with 'doing', an even smaller wrapper around 'echo TEXT > file'.

## Install
Place the script in a new empty directory, that is pointed to by ```$NOTERDIR```, and create an alias to call it from anywhere, (having it in a new directory prevents poluting /usr/bin or other commonplace for installed programs, as the journals file are kept in the same directory (NOTERDIR))

After downloading it, place it in a new empty directory. Then, you need to set-up an environement variable to point to this directory (no '/' after the directory name) :
```
export NOTERDIR="<whereYourDirectoryIs>/<directoryName>"
```
Then, create an alias for noter.sh :
```
alias noter="$NOTERDIR/noter.sh"
```

NOTE : When creating a new (or first) journal, an alias command will be appended to $HOME/.bash_aliases, which should be executed by $HOME/.bashrc. If not, consider adding :
```
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```
to .bashrc.

## Help

```
noter help
noter <option>
    list				- list all availible journals
    add <journalName>			- create a new journal, and add it's alias in \$HOME/.bashrc
    rm <journalName>			- delete the journal, and remove it's alias from \$HOME/.bashrc
    help				- print this help page\n
noter <journalName> <option>
Options :
    add \"entry in your journal\"	- add entrie to the journal
    read <numberOfLines|all>		- read nbOfLines, or all the lines
    grep \"textToGrep\" [-A|-B|-C]	- grep the specified journal, with support for grep's -A, -B, and -C
    help				- print this help page
    doing <lineNumber>			- call 'doing <contentOfLineInJournal>'
    rm <lineNumber>			- delete line number <lineNumber> from the journal\n"
```

## Participating
There are some things that I had the idea of, but haven't coded, writen in TODOs around the file. Feel free to make pull request if you want to participate.
