# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 25;
use ObjectivePerl;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Empty class definition:
@implementation TestClass
@end
my $perlInstance = TestClass->new();
ok($perlInstance, "Perl instantiation of empty class");
ok(ref($perlInstance) eq "TestClass", "Perl instance is correct class");

# Class with parent class
@implementation TestClass2 : TestClass
@end

$perlInstance = TestClass2->new();
ok($perlInstance, "Perl instantiation of empty subclass");
ok(ref ($perlInstance) eq "TestClass2", "Perl instance is correct subclass");
ok(UNIVERSAL::isa($perlInstance, "TestClass"), "Perl instance has correct parent class");

# Class with instance variables
@implementation InstanceClass
	{
	$i, $j, $k;
	}
@end

ok(1, "Parsed ivars without yacking");
$perlInstance = InstanceClass->new();
ok($perlInstance, "Perl instantiation of class with ivars");

# Class with method

@implementation InstanceClass2
- class {
	return ref $self;
}
@end

ok(1, "Parsed method without yacking");
$perlInstance = InstanceClass2->new();
ok($perlInstance, "Perl instantiation of class with method");
ok($perlInstance->class(), "Perl invocation of method");
ok($perlInstance->class() eq "InstanceClass2", "Perl invocation of method returned correct result");

# method and ivar

@implementation InstanceClass3
{  $i, $j, $k; }
- values {
	return [$i, $j, $k];
}

- setValues: $values {
	($i, $j, $k) = @$values;
}
@end

ok(1, "Parsed method and ivars without yacking");
$perlInstance = InstanceClass3->new();
ok($perlInstance, "Perl instantiation of class with method and ivars");
ok($perlInstance->setValues([10, 20, 30]), "Perl invocation of method to set values");
my $values = $perlInstance->values();
ok($values->[0] == 10 && $values->[1] == 20 && $values->[2] == 30, "Perl invocation of method returned correct result");

# inherited instance variables
@implementation InstanceClass4
{
	@protected: $protected;
}
@end;

@implementation Inheritor : InstanceClass4
- protected {
	return $protected;
}
- setProtected: $value {
	$protected = $value;
}
@end

ok(1, "Parsed ivar visibilities without yacking");
$perlInstance = Inheritor->new();
ok($perlInstance, "Perl instantiation of class");
my $opInstance = ~[Inheritor new];
ok(1, "Parsed method invocation correctly without yacking");
ok($opInstance, "Method invocation worked fine");
~[$opInstance setProtected:"TEST"];
ok(~[$opInstance protected] eq "TEST", "Set and get using methods of inherited ivar worked fine");

# embedded methods:
@implementation Inheritor2 : Inheritor
{ $secondProtected; }
- setSecondProtected: $value {
	$secondProtected = $value;
}
- secondProtected {
	return $secondProtected;
}
- setProtected: $value andSecondProtected: $secondValue {
	~[$self setProtected: $value];
	~[$self setSecondProtected: $secondValue];
}
- init {
	~[$self setProtected: "Protected"];
	~[$self setSecondProtected: "Second protected"];
	return $self;
}
@end

$opInstance = ~[~[Inheritor2 new] init];
ok($opInstance, "Instantiated sub-sub-class in obj-p");
ok(~[$opInstance protected] eq "Protected", "Initialised grandparent's protected value using parent's methods");
ok(~[$opInstance secondProtected] eq "Second protected", "Initialised parent's protected value using own methods");
~[$opInstance setProtected: "P" andSecondProtected: "2P"];
ok(~[$opInstance protected] eq "P" && ~[$opInstance secondProtected] eq "2P", "Initialised both values using one method with multiple args");