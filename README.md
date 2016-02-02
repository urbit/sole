# `sole`
Urbit web terminal

`sole` is a frontend for the `%sole-` protocol, used to access console applications such as `:dojo` and `:talk`.

# Developing

The `desk/` folder in this repo mirrors a desk on an urbit `planet`.  Source files live outside of this folder, we compile them in using watchify and then copy the `/desk` onto the desk we're using for development on a planet.

```
npm install
npm run watch
```
## Deploy

Simple:

`cp -r desk/ [$desk_mountpoint]/`

If you have urbit installed in `~/urbit` with a planet called `sampel-sipnym` and have mounted the `home` desk:

`cp -r desk/ ~/urbit/sampel-sipnym/home/`

# Contributing

If you have a patch you'd like to contribute:

- Test your changes using the above instructions
- Fork this repo
- Send us a pull request

# Distribution

Compiled `sole.js` gets periodically shipped to the [urbit core](http://github.com/urbit/urbit).  Each time this compiled files is moved to urbit core its commit message should contain the sha-1 of the commit from this repo.  
