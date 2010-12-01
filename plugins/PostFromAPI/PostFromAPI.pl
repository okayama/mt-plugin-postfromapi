package MT::Plugin::PostFromAPI;
use strict;
use MT;
use MT::Plugin;

our $VERSION = '1.0';

use base qw( MT::Plugin );

###################################### Init Plugin #####################################

@MT::Plugin::PostFromAPI::ISA = qw(MT::Plugin);

my $plugin = new MT::Plugin::PostFromAPI({
    id => 'PostFromAPI',
    key => 'postfromapi',
    name => 'PostFromAPI',
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
    author_name => 'okayama',
    author_link => 'http://weeeblog.net/',
    'version' => $VERSION,
    l10n_class => 'PostFromAPI::L10N',
});

MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        callbacks => {
            'api_pre_save.entry',
                => \&_api_pre_save_entry,
        },
   });
}

###################################### callbacks ######################################

sub _api_pre_save_entry {
    my ( $eh, $app, $obj, $original ) = @_;
    my $text = $obj->text;
    my $check_str_from = quotemeta( '<!--FOLLOWING IS ENTRY DATAS' );
    my $check_str_to = quotemeta( 'ENTRY DATAS END-->' );
    if ( $text && $text =~ /$check_str_from(.*?)$check_str_to/s ) {
        my $datas = $1;
        my $delim = quotemeta( '----' );
        my $check_str_more = quotemeta( 'MORE:' );
        if ( $text =~ /$check_str_more(.*?)$delim/s ) {
            _insert_datas( $obj, 'text_more', $1 ) if $1;
        }
        my $check_str_excerpt = quotemeta( 'EXCERPT:' );
        if ( $text =~ /$check_str_excerpt(.*?)$delim/s ) {
            _insert_datas( $obj, 'excerpt', $1 ) if $1;
        }
        my $check_str_keywords = quotemeta( 'KEYWORDS:' );
        if ( $text =~ /$check_str_keywords(.*?)$delim/s ) {
            _insert_datas( $obj, 'keywords', $1 ) if $1;
        }
        my $check_str_tags = quotemeta( 'TAGS:' );
        if ( $text =~ /$check_str_tags(.*?)$delim/s ) {
            _insert_datas( $obj, 'tags', $1 ) if $1;
        }
        my $check_str_basename = quotemeta( 'BASENAME:' );
        if ( $text =~ /$check_str_basename(.*?)$delim/s ) {
            _insert_datas( $obj, 'basename', $1 ) if $1;
        }
        $text =~ s/$check_str_from.*?$check_str_to//s;
        $obj->text( $text );
    }
1;
}

sub _insert_datas {
    my ( $obj, $target, $text ) = @_;
    chomp $text;
    if ( $target eq 'tags' ) {
        require MT::Tag;
        my $tag_delim = chr( $obj->author->entry_prefs->{tag_delim} );
        my @tags = MT::Tag->split( $tag_delim, $text );
        $obj->add_tags(@tags);
    } else {
        $obj->$target( $text ) if $obj->has_column( $target );
    }
}


1;