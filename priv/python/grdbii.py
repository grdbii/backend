import pkgutil
from pathlib import Path
from signal import signal, alarm, SIGALRM, SIG_IGN
from contextlib import contextmanager
from itertools import product, repeat, starmap
from sys import version_info as version

import yaml
from dill import dumps, loads
from riccipy import SpacetimeMetric, Tensor, Metric
from sympy import latex as sympy_latex, flatten, Array, Matrix

dummy_indices = ['\\mu', '\\nu', '\\sigma', '\\rho', '\\lambda']

utf8_to_latex = {
    '\u0393': '\\Gamma',
}

scalar_names = {
    'ricci_scalar': 'R',
}

@contextmanager
def timeout(time):
    def kill(*args):
        raise TimeoutError

    if time is not "infinity":
        signal(SIGALRM, kill)
        alarm(time // 1000)

    try:
        yield
    finally:
        signal(SIGALRM, SIG_IGN)

def loop(time):
    with timeout(time):
        while True: pass

def make_iterable(item):
    if not isinstance(item, (list, tuple)):
        return [item]
    return item

def latex(expr, name=None, coords=None, covar=None):
    if not isinstance(expr, (Tensor, Metric, Matrix)):
        if name:
            return name + ' = ' + sympy_latex(expr)
        return sympy_latex(expr)

    if not isinstance(expr, Matrix):
        name, coords, covar, expr = name or expr.name, coords or expr.index_types[0].coords, expr.covar, expr.as_array()
    elif None in (name, coords):
        return sympy_latex(expr)
    else:
        expr = Array(expr)

    if name in utf8_to_latex:
        name = utf8_to_latex[name]

    covar = covar or repeat(1, expr.rank())
    items = zip(product(*repeat(coords, expr.rank())), flatten(expr))

    def covar_string(coords):
        upper = ' '.join([c for i, c in enumerate(coords) if covar[i] > 0])
        lower = ' '.join([c for i, c in enumerate(coords) if covar[i] < 0])
        upper = '^{' + upper + '}' if upper else ''
        lower = '_{' + lower + '}' if lower else ''
        return upper + lower

    def latexify(coords, expr):
        # I'm not using `expr.equals(0)` due to performance issues.
        # At the moment, it is assumed that expressions are set explicitly to 0 *a priori*.
        if expr == 0:
            return
        coords, expr = tuple(map(sympy_latex, coords)), sympy_latex(expr)
        return name + covar_string(coords) + ' = ' + expr

    result = list(filter(None, starmap(latexify, items)))
    return result if result else [name + covar_string(dummy_indices[:expr.rank()]) + ' = 0']

def fetch(module_path, time):
    with timeout(time):
        metric_data = []
        for module_info in pkgutil.iter_modules([module_path.decode('utf-8')], prefix="riccipy.metrics."):
            module = __import__(module_info.name, fromlist="dummy")
            if module.__doc__:
                entry = yaml.safe_load(module.__doc__)
                entry = {key.lower(): value for key, value in entry.items()}
                entry["coordinate_type"] = entry.get("coordinates", "")
                entry["notes"] = make_iterable(entry.get("notes", []))
                entry["references"] = make_iterable(entry.get("references", []))
                entry["symmetries"] = make_iterable(entry.get("symmetry", []))
                entry["metric"] = latex(module.metric, name="g", coords=module.coords, covar=(-1, -1))
                entry["coordinates"] = list(map(latex, module.coords))
                entry["variables"] = list(map(latex, make_iterable(module.variables)))
                entry["functions"] = list(map(latex, make_iterable(module.functions)))

                metric = SpacetimeMetric('g', module.coords, module.metric, timelike = False)

                entry["pickle"] = dumps(metric, recurse=True, byref=True)

                metric_data.append(entry)
        return metric_data

def calculate(metric, attribute, time):
    with timeout(time):
        metric = loads(metric)
        attribute = attribute.decode('utf-8')
        tensor = getattr(metric, attribute)
        tensor.simplify()
        result = (
            latex(tensor)
            if attribute not in scalar_names
            else latex(tensor, name=scalar_names[attribute])
        )
        return (result, dumps(metric, recurse=True, byref=True))

if __name__ == "__main__":
    metrics()
