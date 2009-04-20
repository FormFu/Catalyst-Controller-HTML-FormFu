use inc::Module::Install;

name 'Catalyst-Controller-HTML-FormFu';
all_from 'lib/Catalyst/Controller/HTML/FormFu.pm';

requires 'Catalyst::Runtime' => '5.70';
requires 'Catalyst::Component::InstancePerContext';
requires 'Config::Any';
requires 'File::Spec';
requires 'HTML::FormFu' => '0.04001';
requires 'MRO::Compat' => '0.10';
requires 'Moose';
requires 'Regexp::Assemble';
requires 'Scalar::Util';
requires 'Task::Weaken'; # to ensure Scalar::Util was built with weaken()

test_requires 'Catalyst::Action::RenderView';
test_requires 'Catalyst::Plugin::ConfigLoader' => 0.23; # stops warnings under Catalyst 5.80001
test_requires 'Catalyst::Plugin::Session';
test_requires 'Catalyst::Plugin::Session::State::Cookie';
test_requires 'Catalyst::Plugin::Session::Store::File';
test_requires 'Catalyst::View::TT';
test_requires 'Config::General';
test_requires 'Template';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Test::WWW::Mechanize' => '1.16'; # post_ok came in 1.16

license 'perl';

&WriteAll;
