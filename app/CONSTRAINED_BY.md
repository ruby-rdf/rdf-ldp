Lamprey Server Constraints
==========================

Base Container
--------------

A "base" container is created at the address of first GET request sent
to the server upon startup if the repository is empty. Before this,
the server has no resources and will respond `404` to all other
requests.
