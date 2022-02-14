import torch
from torch.nn import Module
import operator

class BufferList(Module):
    r"""Holds buffers in a list.

    BufferList can be indexed like a regular Python list, but parameters it
    contains are properly registered, and will be visible by all Module methods.

    Arguments:
        buffers (iterable, optional): an iterable of :class:`~torch.Tensor`` to add

    Example::

        class MyModule(nn.Module):
            def __init__(self):
                super(MyModule, self).__init__()
                self.buffers = nn.BufferList([nn.Parameter(torch.randn(10, 10)) for i in range(10)])

            def forward(self, x):
                # BufferList can act as an iterable, or be indexed using ints
                for i, p in enumerate(self.params):
                    x = self.params[i // 2].mm(x) + p.mm(x)
                return x
    """

    def __init__(self, buffers=None):
        super(BufferList, self).__init__()
        if buffers is not None:
            self += buffers

    def _get_abs_string_index(self, idx):
        """Get the absolute index for the list of modules"""
        idx = operator.index(idx)
        if not (-len(self) <= idx < len(self)):
            raise IndexError('index {} is out of range'.format(idx))
        if idx < 0:
            idx += len(self)
        return str(idx)

    def __getitem__(self, idx):
        if isinstance(idx, slice):
            return self.__class__(list(self._buffers.values())[idx])
        else:
            idx = self._get_abs_string_index(idx)
            return self._buffers[str(idx)]

    def __setitem__(self, idx, buff):
        idx = self._get_abs_string_index(idx)
        return self.register_buffer(str(idx), buff)

    def __len__(self):
        return len(self._buffers)

    def __iter__(self):
        return iter(self._buffers.values())

    def __iadd__(self, buffers):
        return self.extend(buffers)

    def __dir__(self):
        keys = super(BufferList, self).__dir__()
        keys = [key for key in keys if not key.isdigit()]
        return keys

    def append(self, buff):
        """Appends a given buffer at the end of the list.

        Arguments:
            buff (torch.Tensor): parameter to append
        """
        self.register_buffer(str(len(self)), buff)
        return self

    def extend(self, buffers):
        """Appends buffers from a Python iterable to the end of the list.

        Arguments:
            buffers (iterable): iterable of buffers to append
        """
        if not isinstance(parameters, container_abcs.Iterable):
            raise TypeError("BufferList.extend should be called with an "
                            "iterable, but got " + type(buffers).__name__)
        offset = len(self)
        for i, buff in enumerate(buffers):
            self.register_parameter(str(offset + i), buff)
        return self

    def extra_repr(self):
        child_lines = []
        for k, p in self._buffers.items():
            size_str = 'x'.join(str(size) for size in p.size())
            device_str = '' if not p.is_cuda else ' (GPU {})'.format(p.get_device())
            parastr = 'Parameter containing: [{} of size {}{}]'.format(
                torch.typename(p.data), size_str, device_str)
            child_lines.append('  (' + str(k) + '): ' + parastr)
        tmpstr = '\n'.join(child_lines)
        return tmpstr

