"""Object storage provider abstraction.

Concrete adapters live in submodules and may require optional extras (e.g.
``AzureBlobStorageProvider`` needs the ``storage-azure`` extra). They are
imported from their submodule rather than re-exported here so that the base
contract has no third-party SDK dependency::

    from src.lib.storage.azure import AzureBlobStorageProvider
"""

from src.lib.storage.base import StorageProvider
from src.lib.storage.factory import aclose_storage_provider, get_storage_provider

__all__ = [
    "StorageProvider",
    "aclose_storage_provider",
    "get_storage_provider",
]
