#!/dev/null

package wxViewer;

use strict;
use warnings;
use Devel::SimpleTrace;

use Wx;
use base 'Wx::App';

use wxViewer::Frame;

sub OnInit {
	my ($self) = @_;

	$self->{'frame'} = wxViewer::Frame->new();
	$self->{'frame'}->Show();

	1;
}

1;
