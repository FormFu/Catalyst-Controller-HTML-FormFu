use inc::Module::Install;

name 'Catalyst-Controller-HTML-FormFu';
all_from 'lib/Catalyst/Controller/HTML/FormFu.pm';

requires 'Catalyst::Runtime';
requires 'Config::Any';
requires 'File::Spec';
requires 'HTML::FormFu' => '0.02000';
requires 'NEXT';
requires 'Scalar::Util';
requires 'Task::Weaken'; # to ensure Scalar::Util was built with weaken()

license 'perl';

auto_install();
&WriteAll;
