# ==========================================
# Copyright (C) 2004 kyle dawkins
# kyle-at-centralparksoftware.com
# ObjectivePerl is free software; you can
# redistribute and/or modify it under the 
# same terms as perl itself.
# ==========================================

package ObjectivePerl;

use strict;
use warnings;
use Filter::Simple;
use ObjectivePerl::Runtime;
use ObjectivePerl::Parser;
use ObjectivePerl::InstanceVariable;

our $VERSION = '0.01';

# Preloaded methods go here.
my $parser = ObjectivePerl::Parser->new();

FILTER {
	$parser->initWithString($_);
	$_ = join("", @{$parser->content()});
};

sub import {
	my $module = shift;
	my %params = @_;
	
	while (my ($key, $value) = each %params) {
		if ($key eq "class") {
			$parser->{_currentClass} = $value;
			next;
		}
		# TODO: allow user to change start/end regexps, etc.
	}
}

1;
__END__

=head1 NAME

ObjectivePerl - Objective-C style syntax and runtime for perl

=head1 SYNOPSIS

  use ObjectivePerl;
  @implementation MyClass
  {
     $someInstanceVariable;
     @private: $privateInstanceVariable;
     @protected: $normalInstanceVariable, $anotherInstanceVariable;
  }

  + new {
  	~[$super new];
  }

  - setSomeInstanceVariable: $value {
    $someInstanceVariable = $value;
  }

  - someInstanceVariable {
     return $someInstanceVariable;
  }
  @end

  you can then do
  
  my $instance = ~[MyClass new];
  ~[$instance setSomeInstanceVariable: "Hey you!"];
  print ~[$instance someInstanceVariable]."\n";


=head1 DESCRIPTION

ObjectivePerl adds obj-c style syntax (although it's
implemented with ~[] instead of just []) along with
an obj-c style runtime that is very lightweight but makes
the perl runtime a little more friendly to obj-c
programmers.  

Why, you ask?  Just because.  Obj-c has the easiest-to-read
syntax of just about any language.  It has Smalltalk-style
named arguments that are built into the method signature,
so when you invoke those methods, you're forced to invoke
them neatly, in a very legible fashion:

   ~[$window setTitleTo:"New window" withColor:0xffffff
           andBackground:0x000000];

can never be misunderstood, whereas

   $window->setTitle("New window", 0xffffff, 0x00000);

could be.  Perl offers named arguments already in the
form of hashes, but these are unwieldy (to an obj-c
programmer).

=head2 Defining Classes

The standard perl OO format, (declaring a package,
then setting that package's @ISA array to its parent/s)
is ugly and kludgey.  Using the obj-c style, we end
up with a much clearer declaration of the class:

   @implementation ClassName [: ParentClass] <[Protocols...]>
   ...
   @end

=head2 Real Instance Variables

Furthermore, you get real instance variables.  In your class,
you declare instance variables like this:

   @implementation Rectangle : Shape
   {
	   $width;
	   $height;
   }

and you can use those in your methods directly, like

   - increaseWidth {
	   $width++;
   }

or 

   - area {
	   return $width * $height;
   }

and it will work as expected.  This is much
cleaner than the perlish style of

   sub area {
      return $self->{width} * $self->{height};
   }

=head2 Instance Variable Visibility

Instance variables currently have two possible levels of
visibility, B<private> and B<protected>.  B<Protected> is
the default level of visibility, and means that your class
and any of its subclasses have access to that instance
variable.  B<Private> means that only an instance of
that class --and none of its subclasses--
has access to that instance variable.  When you declare your
instance variables, you specify their visibility like this:

	@implementation MyClass
	{
		$thisVariableDefaultsToProtected;
		@private: $thisVariableIsPrivate;
		@protected: $thisVariableIsProtected;
	}
	...
	@end

B<NOTE>: instance variables can ONLY be scalars.  For the
most part this will not be a problem; you should always
use references anyway.  But if the need arises,
support could be added for other basic types.


=head2 Defining Methods

You can now declare methods as being static or instance
methods.  In obj-c, a "+" indicates a static method, and
a "-" indicates an instance method.  To conform with normal
perl style, instance methods automagically get the variable $self
set correctly and static methods get $className.  You define
methods like this:

	- instanceMethod {
		...
	}

	+ staticMethod {
		...
	}

and you define methods with arguments like this:

	- initWithString:$a andAnotherString:$s {
		... 
	}

and invoke that like this:

	~[SomeObject initWithString:$b andAnotherString: substr($y, 0, 1)];


All methods also have a variable set called '$super'.  This is
a special variable and it lets the parser know that a method is
invoking a method in its superclass.  This has a few special
caveats;  most importantly, you can't choose at runtime which
method to invoke, so this is legal:

   my $self = ~[$super new];

but this isn't:

   my $self = ~[$super [MyClass chooseWhichConstructor]];

I can't see this being a serious limitation, but it arises from the
fact that the SUPER pseudoclass is invisible outside of your methods,
so you can't pass the invocation of a SUPER:: method to the
ObjectivePerl runtime... it has to be invoked right from within your
method.  It may be possible with some judicious 'eval()'-ing but
right now I can't be bothered.

=head2 Class Hierarchy

In general, ObjectivePerl doesn't mess with the class hierarchy.
The only slightly underhand thing it does is to add
B<ObjectivePerl::Object> to the far end of your @ISA array
for classes that you declare using the @implementation syntax.
This allows us to give you default constructors and handlers
and results in more objc-like behaviour.  It also means that you
don't need to provide a constructor at all for your class as the
default one instantiates the object for you.  You B<can>, however,
customise your constructor(s) all you want, as only the "new"
method is supplied.
B<ObjectivePerl::Object> also provides you with a stub "init"
method, that simply returns the object itself.  In obj-c the most
common idiom for object creation is

	id Object = [[SomeClass alloc] init];

and we can emulate this behaviour (optionally) in ObjectivePerl:

	my $object = ~[~[SomeClass new] init];

Ideally, you would create initialisers where appropriate:

	my $objectFromString = ~[~[SomeClass new] initWithString: $string];

=head2 Magic Variables

In your instance methods declared using the "-" syntax, the variable
$self will automatically be set to represent the instance.  $super will
be set to the superclass, so you can invoke SUPER::'s methods just by
saying

	~[$super new];

Any instance variables in your class, and any protected instance
variables in your parent classes, are also available to you magically;
you can just say

	- setValueOfInstanceVariable: $value {
		$instanceVariable = $value;
	}

without all the mess.  Keeps things clean.


=head2 Uses

There are currently two ways to use ObjectivePerl.  The
easiest way is to just say

   use ObjectivePerl;

and everything after that in your source file
will be parsed for ObjectivePerl declarations.  It won't touch
anything else.

Otherwise, you can instantiate the parser and do it yourself:

   use ObjectivePerl::Parser;

   my $parser = ObjectivePerl->new();
   $parser->initWithFile("somePerlFile.pl");
   $parser->dump();

to see what's going on.

=head1 HOW DOES IT WORK?

Well, this version is a bit of a kludge.  It works as a
perl source filter, which means it actually rewrites your
perl code on the fly.  This is not in itself a bad thing;
generating perl code from some non-perl source is pretty
common.  However, it has some disadvantages, which you
can read about below in the B<BUGS> section.

The parser sifts through your code first looking for class
declarations.  If it finds one, it parses it and translates it
into perl.  If it notices that the class descends from an
as-yet-unparsed class, it suspends parsing until that 
super-class is imported (and parsed), and then resumes
parsing where it left off.  This is to enable it to import
the symbols (well, instance variable declarations chiefly)
from the parent class B<before> processing the current class;
it has to do this in order to determine which instance variables
can be used in methods in the current class.  After
that, it locates and rewrites method definitions from
the ObjectivePerl syntax into regular perl subs, locates
any instance variables that are used in methods, and writes out
some perl to import those into the method.  After that, perl
returns control to the newly rewritten program and if all goes well,
your code will be executing.

=head1 BUGS

Dang, there have to be bugs...  as of this release,
the parser is not too smart about quoted close brackets,
so this will cause problems:

   ~[$object printThis:"]"]

will read the quoted closing bracket as the close bracket of
the ObjectivePerl message, rather than the actual one.  When
someone shows me how to use Damian Conway's Text::Balanced
to parse this, the problem will go away.

Another thing that is a bug/feature is that the instance
variable syntax described above will *only* work with
classes that are represented by blessed hashes.  I'll enhance
it later to work with other types of class when the need
arises (or someone sends me a patch).

There are many things that look bug-like to perl
programmers.  For example, the 

	@implementation ClassName : ParentClass <ProtocalName>
	...
	@end

syntax; it appropriates the '@' sign for a use other than
designating an array.  Same goes for the @private/@protected
directives in the instance variable declaration section.  Well,
That's an obj-c thing and makes the resulting code look very familiar
to obj-c programmers.  We will eventually provide an option to
use a different character instead of the '@' sign.

The parser does a lot of regexp matching, and they're pretty
complex regexes, so no doubt there will be times when something
doesn't match that should; it'll probably be because I forgot
about whitespace or something like that.   Fix it and send it to me.

If you specify a parent class in the @implementation line, 
there *must* be a space after your class name and before the colon, so this
is ok:

	@implementation MyClass : SuperClass

but this isn't:

	@implementation MyClass: SuperClass

because I don't know enough about regexes...

Saving the best bug for last; it's really hard to get useful
feedback on errors in your code, because the rewritten
code has wildly different line numbers from your code.  I
will work on smoothing this difference out as much as possible...
and if anyone has ideas on how to improve it, please let me know.

=head1 TO-DO

Still to be done, other than fixing the aforementioned bugs:

  * figure out if the concept of "public" applies here; right now
    instance variables just look like regular lexical variables.
    Since you can't really say $object.$instanceVariable like in
    C++/Java/Python, it's kind of moot.  And kinda dumb, too, 
    anyway... you should be using accessors. :)

  * Allow the user to pass in different start/end regexes for
    parsing ObjectivePerl syntax, and to change the look
    of @implementation into something more perl-ish.

  * Since instance variables can only be scalars, the possibility
	of enhancing the system to use other types (arrays,
    hashes, filehandles, typeglobs...) is there.  I personally
    don't need it but I'll add it if anyone ever wants it.
    Of course, in order for that to happen, someone might actually
    have to B<use> this...

=head1 SEE ALSO

* Any documentation on obj-c or its runtime to learn about the
  terminology and syntax.
* The documentation on Filter::Simple

=head1 AUTHOR

kyle dawkins, E<lt>kyle@centralparksoftware.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by kyle dawkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
