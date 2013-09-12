use strict;
use warnings;

package Device::SMBus;

# PODNAME: Device::SMBus
# ABSTRACT: Perl interface for smbus using libi2c-dev library.
#
# This file is part of Device-SMBus
#
# This software is copyright (c) 2013 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.08'; # VERSION

use 5.010000;

# Dependencies
use Moose;
use Carp;

use IO::File;
use Fcntl;

require XSLoader;
XSLoader::load( 'Device::SMBus', $VERSION );

use constant I2C_SLAVE => 0x0703;


has I2CBusDevicePath => ( is => 'ro', );

has I2CBusFileHandle => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_I2CBusFileHandle',
);


has I2CDeviceAddress => ( is => 'ro', );

has I2CBusFilenumber => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_I2CBusFilenumber',
);

sub _build_I2CBusFileHandle {
    my ($self) = @_;
    my $fh = IO::File->new( $self->I2CBusDevicePath, O_RDWR );
    if ( !$fh ) {
        croak "Unable to open I2C Device File at $self->I2CBusDevicePath";
        return -1;
    }
    $fh->ioctl( I2C_SLAVE, $self->I2CDeviceAddress );
    return $fh;
}

# Implicitly Call the lazy builder for the file handle by using it and get the fileno
sub _build_I2CBusFilenumber {
    my ($self) = @_;
    $self->I2CBusFileHandle->fileno();
}


sub writeQuick {
    my ( $self, $value ) = @_;
    my $retval = Device::SMBus::_writeQuick( $self->I2CBusFilenumber, $value );
}


sub readByte {
    my ($self) = @_;
    my $retval = Device::SMBus::_readByte( $self->I2CBusFilenumber );
}


sub writeByte {
    my ( $self, $value ) = @_;
    my $retval = Device::SMBus::_writeByte( $self->I2CBusFilenumber, $value );
}


sub readByteData {
    my ( $self, $register_address ) = @_;
    my $retval = Device::SMBus::_readByteData( $self->I2CBusFilenumber,
        $register_address );
}


sub writeByteData {
    my ( $self, $register_address, $value ) = @_;
    my $retval = Device::SMBus::_writeByteData( $self->I2CBusFilenumber,
        $register_address, $value );
}


sub readNBytes {
    my ( $self, $reg, $numBytes ) = @_;
    my $retval = 0;
    $retval = ( $retval << 8 ) | $self->readByteData( $reg + $numBytes - $_ )
      for ( 1 .. $numBytes );
    return $retval;
}


sub readWordData {
    my ( $self, $register_address ) = @_;
    my $retval = Device::SMBus::_readWordData( $self->I2CBusFilenumber,
        $register_address );
}


sub writeWordData {
    my ( $self, $register_address, $value ) = @_;
    my $retval = Device::SMBus::_writeWordData( $self->I2CBusFilenumber,
        $register_address, $value );
}


sub processCall {
    my ( $self, $register_address, $value ) = @_;
    my $retval =
      Device::SMBus::_processCall( $self->I2CBusFilenumber, $register_address,
        $value );
}

# Preloaded methods go here.

sub DEMOLISH {
    my ($self) = @_;
    $self->I2CBusFileHandle->close();
}

1;

__END__

=pod

=head1 NAME

Device::SMBus - Perl interface for smbus using libi2c-dev library.

=head1 VERSION

version 0.08

=head1 SYNOPSIS

   use Device::SMBus;
   $dev = Device::SMBus->new(
     I2CBusDevicePath => '/dev/i2c-1',
     I2CDeviceAddress => 0x1e,
   );
   print $dev->readByteData(0x20);

=head1 DESCRIPTION

This is a perl interface to smbus interface using libi2c-dev library. 

=head1 ATTRIBUTES

=head2 I2CBusDevicePath

Device path of the I2C Device. 

 * On Raspberry Pi Model A this would usually be /dev/i2c-0 if you are using the default pins.
 * On Raspberry Pi Model B this would usually be /dev/i2c-1 if you are using the default pins.

=head2 I2CDeviceAddress

This is the Address of the device on the I2C bus, this is usually available in the device Datasheet.

 * for /dev/i2c-0 look at output of `sudo i2cdetect -y 0' 
 * for /dev/i2c-1 look at output of `sudo i2cdetect -y 1' 

=head1 METHODS

=head2 writeQuick

$self->writeQuick($value)

=head2 readByte

$self->readByte()

=head2 writeByte

$self->writeByte()

=head2 readByteData

$self->readByteData($register_address)

=head2 writeByteData

$self->writeByteData($register_address,$value)

=head2 readNBytes

$self->readNBytes($lowest_byte_address, $number_of_bytes);

Read together N bytes of Data in linear register order. i.e. to read from 0x28,0x29,0x2a 

$self->readNBytes(0x28,3);

=head2 readWordData

$self->readWordData($register_address)

=head2 writeWordData

$self->writeWordData($register_address,$value)

=head2 processCall

$self->processCall($register_address,$value)

=head1 USAGE

=over

=item *

This module provides a simplified object oriented interface to the libi2c-dev library for accessing electronic peripherals connected on the I2C bus. It uses Moose.

=back

=head1 see ALSO

=over

=item *

L<Moose>

=item *

L<IO::File>

=item *

L<Fcntl>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/device-smbus/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/device-smbus>

  git clone git://github.com/shantanubhadoria/device-smbus.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 CONTRIBUTORS

=over 4

=item *

Neil Bowers <neil@bowers.com>

=item *

Shantanu <shantanu@cpan.org>

=item *

Shantanu Bhadoria <shantanu.bhadoria@gmail.com>

=item *

Shantanu Bhadoria <shantanu@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
