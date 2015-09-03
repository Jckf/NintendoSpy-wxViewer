#!/dev/null

package NintendoSpy;

use strict;
use warnings;
use Devel::SimpleTrace;

use Time::HiRes 'sleep';
use Device::SerialPort;

sub new {
	my ($class, %opts) = @_;

	my $self = {
		'device' => '/dev/tty.usbmodemfd121'
	};

	$self->{$_} = $opts{$_} for keys %opts;

	$self->{'overflow'} = '';

	$self->{'serial'} = Device::SerialPort->new($self->{'device'}, 1) or die $!;
	$self->{'serial'}->baudrate(115200);
	$self->{'serial'}->parity('none');
	$self->{'serial'}->databits(8);
	$self->{'serial'}->stopbits(1);
	$self->{'serial'}->handshake('none');
	$self->{'serial'}->write_settings();

	bless($self, $class);
}

sub get_status {
	my ($self) = @_;

	if (($self->{'overflow'} =~ tr/\n//) > 2) {
		print '[', scalar(localtime()), '] Falling behind! Discarding stale data.', "\n";
		$self->{'overflow'} = substr($self->{'overflow'}, rindex($self->{'overflow'}, "\n") + 1);
	}

	my $input = $self->{'overflow'};

	if ($input !~ /\n/) {
		while (sleep 0.01) {
			last unless defined $self->{'serial'};
			my ($bytes, $buffer) = $self->{'serial'}->read(255);
			next unless $bytes;
			$input .= $buffer;
			last if $input =~ /\n/;
		}
	}

	return unless $input =~ /\n/;

	($input, $self->{'overflow'}) = split("\n", $input, 2);

	$input =~ s/\0/0/g;

	my ($a, $b, $z, $start, $du, $dd, $dl, $dr) = split('', substr($input, 0, 8));
	my ($u1, $u2, $l, $r, $cu, $cd, $cl, $cr) = split('', substr($input, 8, 16));

	my $x = ord pack('B*', substr($input, 16, 8));
	my $y = ord pack('B*', substr($input, 24, 8));

	$x = - (255 - $x) if $x > 127;
	$y = - (255 - $y) if $y > 127;

	return {
		'a' => $a,
		'b' => $b,
		'z' => $z,
		'start' => $start,
		'd-pad' => {
			'up' => $du,
			'down' => $dd,
			'left' => $dl,
			'right' => $dr
		},
		'l' => $l,
		'r' => $r,
		'camera' => {
			'up' => $cu,
			'down' => $cd,
			'left' => $cl,
			'right' => $cr
		},
		'analog' => {
			'x' => $x,
			'y' => $y
		}
	}
}

sub DESTROY {
	my ($self) = @_;

	$self->{'serial'}->close();
	$self->{'serial'} = undef;
}

1;
