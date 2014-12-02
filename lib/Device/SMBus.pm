use strict;
use warnings;

package Device::SMBus;

# PODNAME: Device::SMBus
# ABSTRACT: Perl interface for smbus using libi2c-dev library.
#
# This file is part of Device-SMBus
#
# This software is copyright (c) 2014 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.07'; # VERSION

# Dependencies
use 5.010000;

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

# Implicitly Call the lazy builder for the file handle by using it and get the filenumber
sub _build_I2CBusFilenumber {
    my ($self) = @_;
    $self->I2CBusFileHandle->fileno();
}


sub fileError {
    my ($self) = @_;
    return $self->I2CBusFileHandle->error();
}


sub writeQuick {
    my ( $self, $value ) = @_;
    my $retval = Device::SMBus::_writeQuick( $self->I2CBusFilenumber, $value );
}


sub readByte {
    my ($self) = @_;
    my $retval = Device::SMBus::_readByte( $self->I2CBusFilenumber );
    return $retval;
}


sub writeByte {
    my ( $self, $value ) = @_;
    my $retval = Device::SMBus::_writeByte( $self->I2CBusFilenumber, $value );
}


sub readByteData {
    my ( $self, $register_address ) = @_;
    my $retval = Device::SMBus::_readByteData( $self->I2CBusFilenumber,
        $register_address );
    return $retval;
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
    return $retval;
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


sub writeBlockData {
    my ( $self, $register_address, $values ) = @_;

    my $value = pack "C*", @{$values};

    my $retval = Device::SMBus::_writeI2CBlockData( $self->I2CBusFilenumber,
        $register_address, $value );
    return $retval;
}


sub readBlockData {
    my ( $self, $register_address, $numBytes ) = @_;

    my $read_val = '0' x ($numBytes);

    my $retval = Device::SMBus::_readI2CBlockData( $self->I2CBusFilenumber,
        $register_address, $read_val );

    my @result = unpack( "C*", $read_val );
    return @result;
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

version 1.07

=head1 SYNOPSIS

   use Device::SMBus;
   $dev = Device::SMBus->new(
     I2CBusDevicePath => '/dev/i2c-1',
     I2CDeviceAddress => 0x1e,
   );
   print $dev->readByteData(0x20);

=head1 DESCRIPTION

This is a perl interface to smbus interface using libi2c-dev library. 

Prerequisites:

For Debian and derivative distros(including raspbian) use the following to install dependencies:

  sudo apt-get install libi2c-dev i2c-tools build-essential

If you are using Angstrom Linux use the following:

  opkg install i2c-tools
  opkg install i2c-tools-dev

For ArchLINUX use the following steps:

  pacman -S base-devel
  pacman -S i2c-tools

Special Instructions for enabling the I2C driver on a Raspberry Pi:

You will need to comment out the driver from the blacklist. currently the
I2C driver isn't being loaded.

     sudo vim /etc/modprobe.d/raspi-blacklist.conf

Replace this line 

     blacklist i2c-bcm2708

with this

     #blacklist i2c-bcm2708

You now need to edit the modules conf file.

     sudo vim /etc/modules

Add these two lines;

     i2c-dev
     i2c-bcm2708

Now run this command(replace 1 with 0 for older model Pi)

     sudo i2cdetect -y 1

If that doesnt work on your system you may alternatively use this:

     sudo i2cdetect -r 1

you should now see the addresses of the i2c devices connected to your i2c bus

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

=head2 fileError

returns IO::Handle->error() for the device handle since the last clearerr

=head2 writeQuick

 $self->writeQuick($value)

This sends a single bit to the device, at the place of the Rd/Wr bit.

=head2 readByte

 $self->readByte()

This reads a single byte from a device, without specifying a device
register. Some devices are so simple that this interface is enough; for
others, it is a shorthand if you want to read the same register as in
the previous SMBus command

=head2 writeByte

 $self->writeByte()

This operation is the reverse of readByte: it sends a single byte
to a device. 

=head2 readByteData

 $self->readByteData($register_address)

This reads a single byte from a device, from a designated register.
The register is specified through the Comm byte.

=head2 writeByteData

 $self->writeByteData($register_address,$value)

This writes a single byte to a device, to a designated register. The
register is specified through the Comm byte. This is the opposite of
the Read Byte operation.

=head2 readNBytes

 $self->readNBytes($lowest_byte_address, $number_of_bytes);

Read together N bytes of Data in linear register order. i.e. to read from 0x28,0x29,0x2a 

 $self->readNBytes(0x28,3);

=head2 readWordData

 $self->readWordData($register_address)

This operation is very like Read Byte; again, data is read from a
device, from a designated register that is specified through the Comm
byte. But this time, the data is a complete word (16 bits).

=head2 writeWordData

 $self->writeWordData($register_address,$value)

This is the opposite of the Read Word operation. 16 bits
of data is written to a device, to the designated register that is
specified through the Comm byte.

=head2 processCall

 $self->processCall($register_address,$value)

This command selects a device register (through the Comm byte), sends
16 bits of data to it, and reads 16 bits of data in return.

=head2 writeBlockData

 $self->writeBlockData($register_address, $values)

Writes a maximum of 32 bytes in a single block to the i2c device.  The supplied $values should be
an array ref containing the bytes to be written.

The register address should be one that is at the beginning of a contiguous block of registers of equal length
to the array of values passed.  Not adhering to this will almost certainly result in unexpected behaviour in
the device.

=head2 readBlockData

 $self->readBlockData($register_address, $numBytes)

Read $numBytes form the given register address,
data is returned as array

The register address is often 0x00 or the value your device expects

common usage with micro controllers that receive and send large amounts of data:
they almost always needs a 'command' to be written to them then they send a response:
e.g:
1) send 'command' with writeBlockData, or writeByteData, for example 'get last telegram'
2) read 'response' with readBlockData of size $numBytes, controller is sending the last telegram

=head2 DEMOLISH

Destructor

=head1 CONSTANTS

=head2 I2C_SLAVE

=head1 USAGE

=over

=item *

This module provides a simplified object oriented interface to the libi2c-dev library for accessing electronic peripherals connected on the I2C bus. It uses Moose.

=back

=head1 SEE ALSO

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

=for stopwords Jonathan Stowe Neil Bowers Shantanu Bhadoria wfreller

=over 4

=item *

Jonathan Stowe <jns+git@gellyfish.co.uk>

=item *

Neil Bowers <neil@bowers.com>

=item *

Shantanu Bhadoria <shantanu att cpan dott org>

=item *

wfreller <wolfgang@freller.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
