use inc::Module::Install;

name 'Catalyst-Controller-HTML-FormFu';
all_from 'lib/Catalyst/Controller/HTML/FormFu.pm';

requires 'Catalyst::Runtime';
requires 'Config::Any';
requires 'File::Spec';
requires 'HTML::FormFu';
requires 'NEXT';
requires 'Scalar::Util';

license 'perl';

auto_install();
&WriteAll;
