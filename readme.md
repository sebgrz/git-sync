### Repos synchronizer

Tool to auto-synchronize repositories within both Github and Gitlab repo hostings

Assumptions:
- intergration with both GH and GL APIs
- create project if doesn't exists
	- gitlab doing this automatically - push mirror to the non-exists project create it

Files struct:
- config.json - providers configuration file (authorization data and so on)
- repos - list repos to synchronize
...
