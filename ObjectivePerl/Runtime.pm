# ==========================================
# Copyright (C) 2004 kyle dawkins
# kyle-at-centralparksoftware.com
# ObjectivePerl is free software; you can
# redistribute and/or modify it under the 
# same terms as perl itself.
# ==========================================

package ObjectivePerl::Runtime;
use strict;

my $_runtime; # we will use a singleton runtime to track classes etc.

sub runtime {
	my $className = shift;
	unless ($_runtime) {
		$_runtime = bless {}, $className;
		$_runtime->init();
	}
	return $_runtime;
}

sub init {
	my $self = shift;
}

sub ObjpMsgSend {
	my $className = shift;
	$className->runtime()->objp_msgSend(@_);
}

sub objp_msgSend {
	my $self = shift;
	my $receiver = shift;
	my $message = shift;
	my $selectors = shift; # an array of key value pairs

	return unless $receiver;
	return unless $message;
	# the first argument is the entry for $message
	my $messageSignature = messageSignatureFromMessageAndSelectors($message, $selectors);
	my $argumentList = [];
	foreach my $selector (@$selectors) {
		push (@$argumentList, $selector->{value});
	}

	# send the message
	if ($receiver->can($messageSignature)) {
		return $receiver->$messageSignature(@$argumentList);
	} elsif ($receiver->can("handleUnknownSelector")) {
		return $receiver->handleUnknownSelector($message, $selectors);
	}
	return undef;
}

sub messageSignatureFromMessageAndSelectors {
	my $message = shift;
	my $arguments = shift;
	my $messageSignature = $message;
	if ($arguments) {
		foreach my $argument (@$arguments) {
			next if ($argument->{key} eq $message);
			$messageSignature .= "_".$argument->{key};
		}
	}
	return $messageSignature;
}

1;
