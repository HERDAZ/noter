#! /bin/bash

if [ $# -lt 1 ]; then
	echo "Small bash program that (badly) manages journals, with a little integration with 'doing', an even smaller wrapper around 'echo TEXT > file'"
	$NOTERDIR/noter.sh help
	exit 1
fi

if [ -z $NOTERDIR ]; then
	echo "Empty NOTERDIR, exiting"
	exit 1
fi

# 1st argument parsing
case $1 in
	list)
		ls $NOTERDIR/*.txt | grep -o -P "\w+(?=.{4}$)"
		exit 0
	;;
	add)
		if [ -n "$2" ]; then
			touch $NOTERDIR/$2.txt
			echo alias $2=\"\$NOTERDIR/noter.sh $2\" >> $HOME/.bash_aliases
			source $HOME/.bashrc
			echo "Might have to reload your shell to actualise the alias"
			exit 0
		else
			echo "Empty note name"
			exit 1
		fi
	;;
	rm)
		if [ -n "$2" ]; then
			rm $NOTERDIR/$2.txt
			lines="$(grep -n "$2" $HOME/.bash_aliases | grep -E -o "^[0-9]+")"
			#echo $lines
			for line in $lines; do
				#echo $line
				sed -i -e "$line d" $HOME/.bash_aliases
			done
			source $HOME/.bashrc
			exit 0
		else
			echo "Empty journal name"
			exit 1
		fi
	;;
	help)
		printf "Usage :
		\r   noter <option>
		\r	list				- list all availible journals
		\r	add <journalName>		- create a new journal, and add it's alias in \$HOME/.bashrc
		\r	rm <journalName>		- delete the journal, and remove it's alias from \$HOME/.bashrc
		\r	help				- print this help page\n
		\r   noter <journalName> <option>
		\r   Options :
		\r	add \"entry in your journal\"	- add entrie to the journal
		\r	read <numberOfLines|all>	- read nbOfLines, or all the lines
		\r	grep \"textToGrep\" [-A|-B|-C]	- grep the specified journal, with support for grep's -A, -B, and -C
		\r	help				- print this help page
		\r	doing <lineNumber>		- call 'doing <contentOfLineInJournal>'
		\r	rm <lineNumber>			- delete line number <lineNumber> from the journal\n"
		exit 1
	;;
	*)
		# File selection
		for note in $(ls $NOTERDIR/*.txt | grep -o -P "\w+(?=.{4}$)"); do
			if [ $1 = $note ]; then
				file=$note
				break
			fi
		done
		if [ -z "$file" ]; then
			echo "File $1.txt doesn't exist"
			exit 1
		fi
	;;
esac



# 2nd argument parsing
case $2 in

	add)
		if [ -z "$3" ]; then
			echo "Empty entry $3"
			exit 1
		elif [ $# -gt 3 ]; then
			echo "Too many arguments ($#), you maybe forgot to use double-quotes (\")"
			exit 1
		fi

		entry="$(date +%d/%m/%y) : $3"

		echo -E "$entry" >> $NOTERDIR/$file.txt
		echo -E "$entry"

		exit 0
	;;

	read)
		
		let lines=$(wc -l $NOTERDIR/$file.txt | grep -o -E "^[0-9]+")

		if [[ $3 = "all" ]]; then
			let number=$lines
		elif [[ $3 =~ ^[0-9]+$ ]]; then
			let number=$3
		else
			let number=10
		fi

		if [ $number -ge $lines ]; then
			let number=$lines-1
		else
			let lines=$number
			let number=$lines-1
		fi

		#echo $lines $number
		tail -n $lines $NOTERDIR/$file.txt | while read f; do
			if [ $number -lt 10 ] && [ $lines -gt 10 ]; then
				echo " $number : $f"
			else
				echo "$number : $f"
			fi
			let number--
		done 

		exit 0
	;;

	#TODO add line number support to journal grep 
	grep)
		context=""

		let arg=4
		for i in {1..2}; do
			case ${!arg} in

				"") # no context args
					break
				;;

				-C)
					let arg=$arg+1
					if [[ ${!arg} =~ ^[0-9]$ ]]; then
						context="-C ${!arg}"
					fi
					break #-C excludes -A and -B, so no need to go further
				;;

				-A)
					let arg=$arg+1
					if [[ ${!arg} =~ ^[0-9]+$ ]]; then
						context=$context" -A ${!arg}"
					else
						echo "'${!arg}' isn't a valid context argument"
						exit 1
					fi
				;;

				-B)
					let arg=$arg+1
					if [[ ${!arg} =~ ^[0-9]+$ ]]; then
						context=$context" -B ${!arg}"
					else
						echo "'${!arg}' isn't a valid context argument"
						exit 1
					fi
				;;

				*)
					echo "'${!arg}' isn't a valid context argument"
					exit 1
				;;
			esac
			let arg=$arg+1
		done

		grep $3 $NOTERDIR/$file.txt $context --color # TODO pipe it with sed or awk to correct the number
		exit 0
	;;

	rm)
		let line=$(wc -l $NOTERDIR/$file.txt | grep -o -E "[0-9]+")

		if [[ $3 =~ ^[0-9]+$ ]]; then
			let line=$line-$3
		elif [ $3 -z ]; then
			:
		else
			echo "'$3' isn't a valid line argument"
			exit 1
		fi

		echo "$line" > $NOTERDIR/deleteBackup
		sed -e "$line p;d" $NOTERDIR/$file.txt >> $NOTERDIR/deleteBackup
		tail $NOTERDIR/deleteBackup -n 1
		sed -i -e "$line d" $NOTERDIR/$file.txt
		exit 0
	;;

	undo)
		#let line=$(echo "3" )
		let savedLineNb=$(head $NOTERDIR/deleteBackup -n 1)
		savedLine=$(tail $NOTERDIR/deleteBackup -n 1)

		tail -n 1 $NOTERDIR/deleteBackup
		
		if [ $savedLineNb -eq 1 ]; then # e.g. if it was the first line that was deleted
			sed -i -e "1 i $savedLine" $NOTERDIR/$file.txt
			exit 1
		else 
			let savedLineNb--
			sed -i -e "$savedLineNb a $savedLine" $NOTERDIR/$file.txt
			exit 1
		fi

	;;

	doing)
		#TODO add an arg to suppress any output
		#TODO add an arg to delete the date when using journal doing

		if [ -z $DOINGDIR ]; then
			echo "Empty DOINGDIR, exiting"
			exit 1
		fi

		if [[ $3 =~ ^[0-9]+$ ]]; then

			let number=$(wc $NOTERDIR/$file.txt -l | grep -P "^\d+" -o)-$3

			line=$(sed -e "$number p;d" $NOTERDIR/$file.txt)
			echo "$line"
			$DOINGDIR/doing.sh "$line"
			exit 1
		fi
	;;

	*)
		echo "'$2' isn't a valid argument"
		printf "Possible args are :
		\r	add
		\r	read
		\r	grep
		\r	rm\n"
		exit 1
		;;
esac
