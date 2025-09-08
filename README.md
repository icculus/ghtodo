# ghtodo

## What is this?

This is a simple Perl script to submit new bugs to a GitHub issue tracker.
This isn't really meant for _bug reporting_, but for quickly adding tasks to a
TODO list.

## Setup

Make a GitHub repository where you'll file bugs with this script. I called
mine "TODO" and made it private.

This script does not need to be installed system-wide. However, it needs the
the Net::GitHub module installed:

Ubuntu/Debian users can install this with:

```bash
sudo apt-get install libnet-github-perl
```

Other distros likely have similar packages, check your package manager. If all
else fails, you can try forcing the issue with CPAN:

```bash
sudo perl -MCPAN -e 'install Net::GitHub;'
```

You'll need a GitHub Personal Access Token. These are free and created through
the GitHub web interface.

Go here: https://github.com/settings/personal-access-tokens/new

Give the token a name like "todo-list", set repository access to
"All repositories", click "Add permissions" and select "Issues" in the popup.

Add whatever description and expiration you like.

Click "Generate token" and copy down the long string of characters it'll
display. This won't be displayed again!

Make a file named ".ghtodo" in your home directory. Put this in it:

```
username=MyGithubUsername
repo=MyGithubRepoName
token=github_pat_[whatver your long string of characters from your GitHub token goes here]
```

Put the script in your PATH, or make an alias, like I did:

```bash
alias todo=$HOME/projects/ghtodo/ghtodo.pl
```

Then run it:

```bash
ghtodo.pl "Take out the trash"
```

This will pop up a text editor if you want to write more about this task. If
you don't, just close the text editor.

If you want to leave a description without a text editor:

```bash
ghtodo.pl "Take out the trash" "You forgot last week..."
```

To leave _no_ description and not be bothered by it:

```bash
ghtodo.pl "Take out the trash" --
```

(I suppose an empty string will work here instead of `--`, too.)

A single dash will read the description from stdin:

```bash
echo "You forgot last week..." |ghtodo.pl "Take out the trash" -
```

And that's it. It'll post a new issue and print the URL.


## Questions and problems

File a bug. Through the web interface, not this script.  :)

