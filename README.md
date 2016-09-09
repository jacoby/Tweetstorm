# NAME

tweetstorm.pl - flood Twitter with your idle thoughts

# SYNOPSIS

    tweetstorm.pl -u username -f file

# DESCRIPTION

This tool is for sending tweetstorms, a flood of numbered tweets, with each 
referring to the previous one for easy reading

# OPTIONS

- **-u**, **--username**

    The username this tweet will be sent as. Required.

- **-f**, **--file**

    A text file, with each line being less than 130 characters. URLs will be minimized. 
    Each line will be numbered and tweeted.
    Required.
    The text to accompany the image. Required.

- **-h**, **--help**

    Display this text

# LICENSE

This is released under the Artistic 
License. See [perlartistic](https://metacpan.org/pod/perlartistic).

# AUTHOR

Dave Jacoby [jacoby.david@gmail.com](https://metacpan.org/pod/jacoby.david@gmail.com)
