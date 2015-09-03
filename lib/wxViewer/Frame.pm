#!/dev/null

package wxViewer::Frame;

use strict;
use warnings;
use Devel::SimpleTrace;

use IO::File;

use Wx;
use base 'Wx::Frame';
use Wx::Event ':everything';

use NintendoSpy;

sub new {
	my ($class, %opts) = @_;

	my $self = $class->SUPER::new(
		undef,
		-1,
		'Hello, World!',
		[-1, -1],
		[175, 190]
	);

	$self->{'stick_x'} = 0;
	$self->{'stick_y'} = 0;

	$self->SetBackgroundColour(Wx::Colour->new(0, 0, 0));

	my $panel = Wx::Panel->new($self);

	open(my $fh, '<', 'skin.conf');
	foreach my $line (<$fh>) {
		$line =~ s/[\r\n]//g;
		$line =~ s/^#.*//g;

		next unless length $line;

		my ($id, $filename, $x, $y, $w, $h) = split(/\t+/, $line);

		my $file = IO::File->new('images/' . $filename, 'r');
		binmode($file);

		my $handler = Wx::PNGHandler->new();
		my $image = Wx::Image->new();
		my $bitmap;

		$handler->LoadFile($image, $file);

		$image->Rescale($w, $h);

		$bitmap = Wx::Bitmap->new($image);

		if ($id eq 'stick') {
			$self->{$id} = $bitmap;
			$self->{'stick_x'} = $x;
			$self->{'stick_y'} = $y;
		} else {
			$self->{$id} = Wx::StaticBitmap->new(
				$self,
				-1,
				$bitmap,
				Wx::Point->new($x, $y)
			);
		}
	}
	close($fh);

	$self->{'spy'} = NintendoSpy->new(
		'device' => '/dev/tty.usbmodemfd12141'
	);

	$self->{'timer'} = Wx::Timer->new($self, 1);

	EVT_PAINT($self, sub {
		$self->paint();
	});
	EVT_TIMER($self, 1, sub {
		$self->paint();
	});

	$self->{'timer'}->Start(10);

	$self;
}

sub paint {
	my ($self) = @_;

	my $dc = new Wx::PaintDC($self);

	my $status = $self->{'spy'}->get_status();

	$self->{'bt_a'}->Show($status->{'a'});
	$self->{'bt_b'}->Show($status->{'b'});
	$self->{'bt_start'}->Show($status->{'start'});

	$self->{'bt_cu'}->Show($status->{'camera'}->{'up'});
	$self->{'bt_cd'}->Show($status->{'camera'}->{'down'});
	$self->{'bt_cl'}->Show($status->{'camera'}->{'left'});
	$self->{'bt_cr'}->Show($status->{'camera'}->{'right'});

	$self->{'bt_du'}->Show($status->{'d-pad'}->{'up'});
	$self->{'bt_dd'}->Show($status->{'d-pad'}->{'down'});
	$self->{'bt_dl'}->Show($status->{'d-pad'}->{'left'});
	$self->{'bt_dr'}->Show($status->{'d-pad'}->{'right'});

	$self->{'bt_l'}->Show($status->{'l'});
	$self->{'bt_r'}->Show($status->{'r'});
	$self->{'bt_z'}->Show($status->{'z'});

	$dc->DrawBitmap(
		$self->{'stick'},
		$self->{'stick_x'} + ($status->{'analog'}->{'x'} / 1),
		$self->{'stick_y'} - ($status->{'analog'}->{'y'} / 1),
		1
	);

	$self->Refresh();
}

1;
