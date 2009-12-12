# DashOff - A plugin for Movable Type.
# Copyright (c) 2007, Beau Smith

package MT::Plugin::DashOff;

use 5.006;    # requires Perl 5.6.x
use MT 4.0;   # requires MT 4.0 or later

use base 'MT::Plugin';
our $VERSION = '1.1';

my $plugin;
MT->add_plugin($plugin = __PACKAGE__->new({
    name            => "DashOff",
    version         => $VERSION,
    description     => "Adds a sidebar dashboard widget that lists all your blogs with some handy links",
    author_name     => "Beau Smith",
    author_link     => "http://www.beausmith.com/",
    plugin_link     => "http://www.beausmith.com/mt/plugins/dashoff/",
    settings        => new MT::PluginSettings([
        ['dashoff_sort', { Default => 'name' }],
        ['dashoff_direction', { Default => 'ascend' }],
        ['dashoff_counts', { Default => 0 }],
    ]),
    system_config_template => 'dashoff_config.tmpl'
}));

# Allows external access to plugin object: MT::Plugin::MyPlugin->instance
sub instance { $plugin; }

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        applications => {
            cms => {
                widgets => {
                    dashoff => {
                        label => 'DashOff',
                        template => 'dashoff_widget.tmpl',
                        handler => \&dashoff_widget,
                        singular => 1,
                        set => 'sidebar',
                    }
                }
            }
        }
    });
}

sub dashoff_widget {
    my $app = shift;
    my ($tmpl, $param) = @_;
    my $q = $app->param;
    require MT::Blog;
    require MT::Permission;
    require MT::Entry;
    require MT::Comment;
    my $author = $app->user;

    my %args = (
        sort => $plugin->get_config_value('dashoff_sort') || 'name',
        direction => $plugin->get_config_value('dashoff_direction') || 'ascend',
        join => MT::Permission->join_on('blog_id',
                               { author_id => $author->id }),
    );

    my @blogs = MT::Blog->load(undef, \%args);
    my $i = 1;
    
    $param->{blog_loop} = $app->make_blog_list(\@blogs);
    delete $param->{blog_loop} unless ref $param->{blog_loop};
    
    foreach my $blog (@{$param->{blog_loop}}) {
        my $perms   = $author->permissions($blog->{id});
        
        $blog->{can_manage_pages} = $perms->can_manage_pages;
        $blog->{can_upload} = $perms->can_upload || $perms->can_edit_assets;
        $blog->{can_edit_assets} = $perms->can_edit_assets;
        
        $blog->{show_create_link} = $blog->{can_create_post} || $blog->{can_manage_pages} || $blog->{can_upload};
        
        if ($plugin->get_config_value('dashoff_counts')) {
            $blog->{num_pages} = MT::Entry->count( { blog_id => $blog->{id}, class => 'page' } ) || 0;
            $blog->{num_assets} = MT::Asset->count({ blog_id => $blog->{id} }) || 0;
        }
        
        $blog->{dashoff_counts} = $plugin->get_config_value('dashoff_counts') || 0;
        
    }
}

1;
