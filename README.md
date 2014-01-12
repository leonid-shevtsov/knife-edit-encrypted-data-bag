This script has several important improvements over typical methods:

* validates your data bag after editing, and if you have syntax errors, it returns you to the editor instead of failing;
* won't update data bag file if no changes were made (the typical method would re-salt the file, making changes for no reason)
* can autogenerate a data bag key;

## Usage

Drop into your "kitchen" directory. Then

    chmod +x edit_data_bag.rb
    ./edit_data_bag.rb <bag> <item name>

## TODO

It should be merged with Chef, but they have an awful policy towards core contributions, and a long list of issues in the bug tracker, so I don't even see the point.